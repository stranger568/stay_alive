ability_cancel = class({})

function ability_cancel:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

function ability_cancel:OnSpellStart()
	if not IsServer() then return end
	self:GetCaster():Interrupt()
	if self:GetCaster().timer then
		Timers:RemoveTimer(self:GetCaster().timer)
	end
	if self:GetCaster().build_particle then
		ParticleManager:DestroyParticle(self:GetCaster().build_particle, true)
		ParticleManager:ReleaseParticleIndex(self:GetCaster().build_particle)
	end
	self:GetCaster():DestroyBuilding(self:GetCaster():entindex())
end