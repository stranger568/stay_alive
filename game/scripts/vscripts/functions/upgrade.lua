LinkLuaModifier( "modifier_build_attack_range", "modifiers/builds/modifier_build_attack_range", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_build_disable_turning", "modifiers/builds/modifier_build_disable_turning", LUA_MODIFIER_MOTION_NONE )

ability_upgrade = class({})

function ability_upgrade:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function ability_upgrade:GetChannelTime()
	local tower_ability = self:GetCaster():FindAbilityByName(self:GetCaster():GetUnitName())
	if tower_ability then
		return tower_ability:GetLevelSpecialValueFor("upgrade_time_per_level", self:GetCaster():GetLevel())
	end
end

function ability_upgrade:OnAbilityPhaseStart()
	local abilKVs = GetAbilityKeyValuesByName(self:GetCaster():GetUnitName())
	local level = self:GetCaster():GetLevel()
	if abilKVs.AbilityValues.gold_cost_upgrade ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.gold_cost_upgrade)
		if self:GetCaster():GetOwner():GetGold() < tonumber(split_kv[level + 1]) then
			utl:DisplayError(self:GetCaster():GetOwner():GetPlayerID(), "#notification_st_no_gold")
			return false
		end
	end
	return true
end

function ability_upgrade:OnSpellStart()
	if not IsServer() then return end
	local point = self:GetCaster():GetAbsOrigin()
	local unitKV = GetUnitKeyValuesByName(self:GetCaster():GetUnitName())
	local abilKVs = GetAbilityKeyValuesByName(self:GetCaster():GetUnitName())
	local level = self:GetCaster():GetLevel()

	local build_particle = ParticleManager:CreateParticle(unitKV.BuildParticle, PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(build_particle, 0, point)
	ParticleManager:SetParticleControl(build_particle, 1, point)

	-- Стоимость Грейда --

	if abilKVs.AbilityValues.gold_cost_upgrade ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.gold_cost_upgrade)
		self:GetCaster():GetOwner():ModifyGold(tonumber(split_kv[level + 1]) * -1, false, 7)
	end
	---------------------------------------------------------------------------------------------------

	self:GetCaster().build_particle = build_particle
end

function ability_upgrade:OnChannelFinish(bInterrupted)

    local point = self:GetCaster():GetAbsOrigin()
    local name = self:GetCaster():GetUnitName()
    local owner = self:GetCaster():GetOwner()
    local level = self:GetCaster():GetLevel()
    local abilKVs_old = GetAbilityKeyValuesByName(self:GetCaster():GetUnitName())

    if bInterrupted then

		-- Возврат денег за отмену грейда --

		if abilKVs_old.AbilityValues.gold_cost_upgrade ~= nil then
			local split_kv = utl:split(abilKVs_old.AbilityValues.gold_cost_upgrade)
			self:GetCaster():GetOwner():ModifyGold(tonumber(split_kv[level + 1]), false, 7)
		end
		---------------------------------------------------------------------------------------------------

    	if self:GetCaster().build_particle then
    		ParticleManager:DestroyParticle(self:GetCaster().build_particle,false)
			ParticleManager:ReleaseParticleIndex(self:GetCaster().build_particle)
    	end
    	return
    end
    --------- Удаление прошлой и создание регистрация новой башни ----------------------------------

    UTIL_Remove(self:GetCaster())
    local new_build = CreateUnitByName(name, point, false, owner, owner, owner:GetTeamNumber())
    buildinghelper:RegisterBuilding(new_build, owner:GetTeamNumber(), point, owner, owner:GetPlayerID())

    --------- Установка характеристик башни ---------

    new_build:AddNewModifier(new_build, nil, "modifier_build_disable_turning", {})

    while new_build:GetLevel() < level + 1 do
    	new_build:CreatureLevelUp(1)
    end

    local abilKVs = GetAbilityKeyValuesByName(new_build:GetUnitName())

    local max_level_upgrade = utl:split(abilKVs.AbilityValues.max_upgrade_level)

    if max_level_upgrade and level+1 < tonumber(max_level_upgrade[1]) then
    	new_build:AddAbility("ability_upgrade")
    end

	local ability_sell = new_build:AddAbility("ability_sell")

	local ability_value = new_build:AddAbility(new_build:GetUnitName())
	if ability_value then
		ability_value:SetHidden(true)
	end

	-- Установка новой модели

	if abilKVs["model_level_"..level+1] ~= nil then
		new_build:SetModel(abilKVs["model_level_"..level+1])
		new_build:SetOriginalModel(abilKVs["model_level_"..level+1])
	end

	-- Установка новой цены постройки --

	if abilKVs.AbilityValues.gold_cost_upgrade ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.gold_cost_upgrade)
		new_build.price = tonumber(split_kv[level + 1])
	end
	---------------------------------------------------------------------------------------------------

	-- Здоровье --
	if abilKVs.AbilityValues.upgrade_health_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_health_per_level)
		new_build:SetBaseMaxHealth(tonumber(split_kv[level + 1]))
		new_build:SetMaxHealth(tonumber(split_kv[level + 1]))
		new_build:SetHealth(tonumber(split_kv[level + 1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Броня --
	if abilKVs.AbilityValues.upgrade_armor_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_armor_per_level)
		new_build:SetPhysicalArmorBaseValue(tonumber(split_kv[level + 1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Урон --
	if abilKVs.AbilityValues.upgrade_damage_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_damage_per_level)
		new_build:SetBaseDamageMin(tonumber(split_kv[level + 1]))
		new_build:SetBaseDamageMax(tonumber(split_kv[level + 1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Дальность атаки --
	if abilKVs.AbilityValues.upgrade_range_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_range_per_level)
		local modifier_range = new_build:AddNewModifier(new_build, nil, "modifier_build_attack_range", {})
		if modifier_range then
			modifier_range:SetStackCount(tonumber(split_kv[level + 1]))
		end
	end
	---------------------------------------------------------------------------------------------------

	-- Скорость атаки --
	if abilKVs.AbilityValues.upgrade_attackspeed_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_attackspeed_per_level)
		new_build:SetBaseAttackTime(tonumber(split_kv[level + 1]))
	end
	---------------------------------------------------------------------------------------------------
end