modifier_build_buildingtime = class({})

function modifier_build_buildingtime:IsHidden() return true end

function modifier_build_buildingtime:IsPurgable() return false end

function modifier_build_buildingtime:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end