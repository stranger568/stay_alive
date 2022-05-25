LinkLuaModifier( "modifier_repair_target", "functions/repair", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_repair_parent", "functions/repair", LUA_MODIFIER_MOTION_NONE )

modifier_repair_order = class({})

function modifier_repair_order:IsHidden() return true end
function modifier_repair_order:IsPurgable() return false end
function modifier_repair_order:RemoveOnDeath() return false end

function modifier_repair_order:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
end

function modifier_repair_order:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_FIXED_ATTACK_RATE
	}
end

function modifier_repair_order:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_repair_order:GetModifierFixedAttackRate()
	return 0.25
end

function modifier_repair_order:OnOrder(params)
	if not IsServer() then return end

	if self.parent ~= params.unit then return end

	self:repair_cancel()

	if 	( params.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET or params.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET ) and (params.target.DestroyBuilding ~= nil) then
		self.parent.repair_target = params.target
		local self_coord = self.parent:GetAbsOrigin()
		local target_coord = params.target:GetAbsOrigin()

		if ((self_coord-target_coord):Length2D() < 200) then
			self.parent:Interrupt()
			self:StartIntervalThink(0)
		else
			self:StartIntervalThink(0.25)
		end
	end
end

function modifier_repair_order:repair_cancel()
	if self.parent.repair_target ~= nil then
		self:StartIntervalThink(-1)
		self.parent.repair_target = nil

		if (self.parent.repair_modifier_target ~= nil) then
			self.parent.repair_modifier_target:Destroy()
			self.parent.repair_modifier_parent:Destroy()
			self.parent.repair_modifier_parent = nil
			self.parent.repair_modifier_target = nil
			--if self.parent.repair_particle then
				--ParticleManager:DestroyParticle(self.parent.repair_particle, false)
				--ParticleManager:ReleaseParticleIndex(self.parent.repair_particle)
			--end
		end
	end
end

function modifier_repair_order:OnIntervalThink()
	if not IsServer() then return end

	local parent = self.parent
	local self_coord = parent:GetAbsOrigin()
	local target_coord = parent.repair_target:GetAbsOrigin()

	if ((self_coord-target_coord):Length2D() < 200) then
		self:StartIntervalThink(-1)
		parent:Interrupt()

		parent.repair_modifier_parent = parent:AddNewModifier(parent, nil, "modifier_repair_parent", {})
		parent.repair_modifier_target = parent.repair_target:AddNewModifier(parent, nil, "modifier_repair_target", {})
		--parent.repair_particle = ParticleManager:CreateParticle("particles/econ/items/pugna/pugna_ti10_immortal/pugna_ti10_immortal_life_drain_gold.vpcf", PATTACH_CENTER_FOLLOW, parent)
		--ParticleManager:SetParticleControlEnt(parent.repair_particle, 0, parent.repair_target, PATTACH_CENTER_FOLLOW, "attach_hitloc", target_coord, true)
		--ParticleManager:SetParticleControlEnt(parent.repair_particle, 1, parent, PATTACH_CENTER_FOLLOW, "attach_hitloc", self_coord, true)
	else
		parent:MoveToNPC(parent.repair_target)
	end
end

modifier_repair_parent = class({})

modifier_repair_parent.repair_sound = {
	["npc_dota_hero_omniknight"] = "Hero_Omniknight.Attack",
}

function modifier_repair_parent:IsHidden() return true end
function modifier_repair_parent:IsPurgable() return false end

function modifier_repair_parent:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_repair_parent:OnIntervalThink()
	if not IsServer() then return end
	self:GetParent():FadeGesture(ACT_DOTA_ATTACK)
	self:GetParent():FadeGesture(ACT_DOTA_ATTACK2)
	self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 2.5)
	self:GetParent():EmitSound(self.repair_sound[self:GetParent():GetUnitName()])
end

function modifier_repair_parent:OnDestroy()
	if not IsServer() then return end
	local modifier = self:GetParent():FindModifierByName("modifier_repair_order")
	if modifier then
		modifier:repair_cancel()
	end
end

modifier_repair_target = class({})

function modifier_repair_target:IsHidden() return true end
function modifier_repair_target:IsPurgable() return false end

function modifier_repair_target:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_repair_target:OnIntervalThink()
	if not IsServer() then return end
	self:GetParent():SetHealth(self:GetParent():GetHealth() + (15 * 0.25) )
end

function modifier_repair_target:OnDestroy()
	if not IsServer() then return end
	local modifier = self:GetCaster():FindModifierByName("modifier_repair_order")
	if modifier then
		modifier:repair_cancel()
	end
end