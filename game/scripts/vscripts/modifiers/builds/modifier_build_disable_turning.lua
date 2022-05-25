modifier_build_disable_turning = class({})

function modifier_build_disable_turning:IsHidden() return true end

function modifier_build_disable_turning:IsPurgable() return false end

function modifier_build_disable_turning:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DISABLE_TURNING,
		MODIFIER_PROPERTY_ALWAYS_AUTOATTACK_WHILE_HOLD_POSITION,
	}
	return funcs
end

function modifier_build_disable_turning:GetModifierDisableTurning()
	return 0
end

function modifier_build_disable_turning:GetAlwaysAutoAttackWhileHoldPosition()
	return 1
end

