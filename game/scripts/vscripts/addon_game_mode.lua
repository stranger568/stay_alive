if StayAliveMode == nil then
	StayAliveMode = class({})
end

require("player_info")
require("util")
require("lib/timers")
require("lib/buildinghelper")
require( "panorama/playertables" )
require( "panorama/worldpanels" )

LinkLuaModifier( "modifier_repair_order", "functions/repair.lua", LUA_MODIFIER_MOTION_NONE )

function Precache( context )
	PrecacheResource("particle_folder", "particles/buildinghelper", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts", context )  
end

function Activate()
	StayAliveMode:InitGameMode()
end

function StayAliveMode:InitGameMode()
	buildinghelper:InitBuildingHelper()
	GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_omniknight")
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 10 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( self, "OnNPCSpawned" ), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( self, "ExecuteOrderFilter" ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( self, "OnEntityKilled"), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(self, 'OnConnectFull'), self)
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( self, 'OnGameRulesStateChange' ), self )
end

function StayAliveMode:OnConnectFull(data)
	local player_index = EntIndexToHScript( data.index )
	if player_index == nil then
		return
	end
	PlayerInfo:RegisterPlayerInfo(data.PlayerID)
end

function StayAliveMode:OnNPCSpawned( event )
	local player = EntIndexToHScript(event.entindex)
	if player:IsRealHero() then
		player:AddNewModifier(player, nil, "modifier_repair_order", {})
	end
end

function StayAliveMode:OnEntityKilled(keys)
	local ent = EntIndexToHScript(keys.entindex_killed)

	self.pfx = ParticleManager:CreateParticle("particles/overlord_anime/overlord_screen_white.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	
	if (ent.DestroyBuilding ~= nil) then ent:DestroyBuilding(keys.entindex_killed) end
end

function StayAliveMode:OnGameRulesStateChange(params)
	local nNewState = GameRules:State_Get()

	if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		buildinghelper:SpawnCenterWalls()
	end
end

function StayAliveMode:ExecuteOrderFilter( filterTable )
	local unit
	if filterTable.units and filterTable.units["0"] then
		unit = EntIndexToHScript(filterTable.units["0"])
	end
	local target = filterTable.entindex_target ~= 0 and EntIndexToHScript(filterTable.entindex_target) or nil
	local orderType = filterTable["order_type"]

	if unit and unit:IsRealHero() then
		if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or 
			orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET  or 
			orderType == DOTA_UNIT_ORDER_ATTACK_MOVE  or 
			orderType == DOTA_UNIT_ORDER_ATTACK_TARGET or 
			orderType == DOTA_UNIT_ORDER_CAST_POSITION or 
			orderType == DOTA_UNIT_ORDER_CAST_TARGET or 
			orderType == DOTA_UNIT_ORDER_STOP or 
			orderType == DOTA_UNIT_ORDER_MOVE_TO_DIRECTION or 
			orderType == DOTA_UNIT_ORDER_HOLD_POSITION then

			if unit.move_to_build_timers ~= nil then
				for _, timer in pairs(unit.move_to_build_timers) do
					Timers:RemoveTimer(timer)
					print("Удалил прошлый таймер", timer)
				end
				unit.move_to_build_timers = nil
			end
		end

		if orderType == DOTA_UNIT_ORDER_HOLD_POSITION or orderType == DOTA_UNIT_ORDER_STOP then
			unit:MoveToPosition(unit:GetAbsOrigin())
			return false
		end
	end

	return true
end