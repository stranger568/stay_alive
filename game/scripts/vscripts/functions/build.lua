LinkLuaModifier( "modifier_build_attack_range", "modifiers/builds/modifier_build_attack_range", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_build_buildingtime", "modifiers/builds/modifier_build_buildingtime", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_build_disable_turning", "modifiers/builds/modifier_build_disable_turning", LUA_MODIFIER_MOTION_NONE )

build_wall = class({})

function build_wall:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function build_wall:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end

-- При создании новой абилки на создание постройки копируешь эту хуйню и меняешь на название абилки

build_defend_tower = class({})

function build_defend_tower:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function build_defend_tower:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end

----------------------------------------------------------------------------------------------------

defend_tower_poison = class({})

function defend_tower_poison:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function defend_tower_poison:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end

defend_tower_rapid = class({})

function defend_tower_rapid:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function defend_tower_rapid:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end

defend_tower_stun = class({})

function defend_tower_stun:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function defend_tower_stun:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end

defend_tower_range = class({})

function defend_tower_range:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function defend_tower_range:OnSpellStart()
	if not IsServer() then return end
	local player = self:GetCaster():GetPlayerOwner()
	local player_id = player:GetPlayerID()
	local abilKVs = GetAbilityKeyValuesByName(self:GetAbilityName())

	local data = {}

	data.ability = self
	data.caster = self:GetCaster()
	data.build_name = abilKVs.UnitName
	data.callback = build_building_middle
	data.callback_data = data
	buildinghelper:Start_Building(data)
end









function build_building_middle(argv, data)

	local player = data.caster:GetPlayerOwner()
	local abilKVs = GetAbilityKeyValuesByName(data.ability:GetAbilityName())
	local location = buildinghelper:SnapToGrid(Vector(argv.X,argv.Y,argv.Z))
	local check_pla = buildinghelper:CheckPlace(argv.X,argv.Y,player:GetTeam())

	if check_pla == false then
		buildinghelper:cancel_command(argv)
		return
	end

	if abilKVs.AbilityValues.gold_cost_upgrade ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.gold_cost_upgrade)
		if data.caster:GetGold() < tonumber(split_kv[1]) then
			buildinghelper:cancel_command(argv)
			utl:DisplayError(data.caster:GetPlayerID(), "#notification_st_no_gold")
			return
		end
	end

	local distance_start = (location - data.caster:GetAbsOrigin()):Length2D()

	if (argv.Shift == 0 and data.caster.move_to_build_timers ~= nil) then
		for _, timer in pairs(data.caster.move_to_build_timers) do
			Timers:RemoveTimer(timer)
			print("Удалил прошлый таймер", timer)
		end
		data.caster.move_to_build_timers = nil
	end

	if data.caster.move_to_build_timers == nil then
		data.caster.move_to_build_timers = {}
	end

	if distance_start > 200 then
		data.caster:MoveToPosition(location)
		data.caster.move_to_build_timers[#data.caster.move_to_build_timers + 1] = 
		Timers:CreateTimer(0.03, function()
			data.caster:MoveToPosition(location)
			if not IsValidEntity(data.caster) or not data.caster:IsAlive() then return end
            local distance = (location - data.caster:GetAbsOrigin()):Length2D()
            
            if distance > 200 then
                return 0.03
            else
                CreateBuildingBuild(argv, data)
                table.remove(data.caster.move_to_build_timers, 1)
            end
		end)
	else
		CreateBuildingBuild(argv, data)
	end
end

function CreateBuildingBuild(argv, data)

	local player = data.caster:GetPlayerOwner()
	local abilKVs = GetAbilityKeyValuesByName(data.ability:GetAbilityName())
	local location = buildinghelper:SnapToGrid(Vector(argv.X,argv.Y,argv.Z))
	local check_pla = buildinghelper:CheckPlace(argv.X,argv.Y,player:GetTeam())

	if ( (check_pla == false) or (check_res == false) ) then
		argv.cmd = "nomoney"
		buildinghelper:cancel_command(argv)
		return
	end

	local unit = buildinghelper:AddBuilding( location, argv.PlayerID, argv.Shift, data.build_name)
	local unitKV = GetUnitKeyValuesByName(abilKVs.UnitName)

	unit.build_particle = ParticleManager:CreateParticle(unitKV.BuildParticle, PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleControl( unit.build_particle, 0, location)
	ParticleManager:SetParticleControl( unit.build_particle, 1, location)



	-- Стоимость постройки --

	if abilKVs.AbilityValues.gold_cost_upgrade ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.gold_cost_upgrade)
		data.caster:ModifyGold(tonumber(split_kv[1]) * -1, false, 7)
		unit.price = tonumber(split_kv[1])
	end
	---------------------------------------------------------------------------------------------------

	-- Здоровье --
	if abilKVs.AbilityValues.upgrade_health_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_health_per_level)
		unit:SetBaseMaxHealth(tonumber(split_kv[1]))
		unit:SetMaxHealth(tonumber(split_kv[1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Броня --
	if abilKVs.AbilityValues.upgrade_armor_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_armor_per_level)
		unit:SetPhysicalArmorBaseValue(tonumber(split_kv[1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Урон --
	if abilKVs.AbilityValues.upgrade_damage_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_damage_per_level)
		unit:SetBaseDamageMin(tonumber(split_kv[1]))
		unit:SetBaseDamageMax(tonumber(split_kv[1]))
	end
	---------------------------------------------------------------------------------------------------

	-- Дальность атаки --
	if abilKVs.AbilityValues.upgrade_range_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_range_per_level)
		local modifier_range = unit:AddNewModifier(unit, nil, "modifier_build_attack_range", {})
		if modifier_range then
			modifier_range:SetStackCount(tonumber(split_kv[1]))
		end
	end
	---------------------------------------------------------------------------------------------------

	-- Скорость атаки --
	if abilKVs.AbilityValues.upgrade_attackspeed_per_level ~= nil then
		local split_kv = utl:split(abilKVs.AbilityValues.upgrade_attackspeed_per_level)
		unit:SetBaseAttackTime(tonumber(split_kv[1]))
	end
	---------------------------------------------------------------------------------------------------

	local ability_upgrade = unit:AddAbility("ability_upgrade")
	if ability_upgrade then
		ability_upgrade:SetHidden(true)
	end

	local ability_cancel = unit:AddAbility("ability_cancel")

	local ability_sell = unit:AddAbility("ability_sell")
	if ability_sell then
		ability_sell:SetHidden(true)
	end

	local ability_value = unit:AddAbility(data.ability:GetAbilityName())
	if ability_value then
		ability_value:SetHidden(true)
	end

	unit:SetBaseHealthRegen(0)
	unit:SetHealth(1)
	unit:AddNewModifier(unit, nil, "modifier_build_buildingtime", {duration = abilKVs.BuildingTime})
	unit:AddNewModifier(unit, nil, "modifier_build_disable_turning", {})

	local timer_build = 0


	Timers:CreateTimer(0.1, function()
		timer_build = timer_build + 0.1

		if unit == nil then return end
		if unit:IsNull() then return end
		if not unit:IsAlive() then return end

		if timer_build >= tonumber(abilKVs.BuildingTime) then
			return
		end

		unit:SetHealth(unit:GetHealth() + ((unit:GetMaxHealth() / abilKVs.BuildingTime) * 0.1) )
		return 0.1
	end)

	unit.timer = Timers:CreateTimer({ endTime = abilKVs.BuildingTime, callback = build_building_end, caster = data.caster, unit = unit })
end

function build_building_end(keys)
	local unit = keys.unit

	if unit == nil then return end
	if unit:IsNull() then return end
	if not unit:IsAlive() then return end

	if unit.build_particle then
		ParticleManager:DestroyParticle(unit.build_particle,false)
		ParticleManager:ReleaseParticleIndex(unit.build_particle)
	end

	local ability_upgrade = unit:FindAbilityByName("ability_upgrade")
	if ability_upgrade then
		ability_upgrade:SetHidden(false)
	end

	unit:SwapAbilities("ability_cancel", "ability_sell", false, true)

	local ability_cancel = unit:FindAbilityByName("ability_cancel")
	if ability_cancel then
		ability_cancel:SetHidden(true)
	end

	local ability_sell = unit:FindAbilityByName("ability_sell")
	if ability_sell then
		ability_sell:SetHidden(false)
	end	
end