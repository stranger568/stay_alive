modifier_build_attack_range = class({})

function modifier_build_attack_range:IsHidden() return true end

function modifier_build_attack_range:IsPurgable() return false end

function modifier_build_attack_range:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}

	return decFuncs
end

function modifier_build_attack_range:GetModifierAttackRangeBonus()
	return self:GetStackCount()
end