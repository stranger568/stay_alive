if (_G.buildinghelper) == nil then
	_G.buildinghelper = class({})
end

function buildinghelper:InitBuildingHelper()
	buildinghelper:InitBuildsZone()
	CustomGameEventManager:RegisterListener( "building_helper_build_command", Dynamic_Wrap(buildinghelper, "build_command"))
	CustomGameEventManager:RegisterListener( "building_helper_cancel_command", Dynamic_Wrap(buildinghelper, "cancel_command"))
end



------------------------------------------------------
--создаём дамп здания передаём эвент в панораму
------------------------------------------------------

function buildinghelper:Start_Building(keys)
	local ability = keys.ability
	local abilName = ability:GetAbilityName()
	local player = keys.caster:GetPlayerOwner()

	if (player.mgd ~= nil) then
		player.mgd:RemoveSelf()
		player.mgd = nil
	end

	local AbilKV = GetAbilityKeyValuesByName(abilName)
	player.mgd = CreateUnitByName(AbilKV.UnitName, Vector(11000, 11000, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)

	if (keys.callback ~= nil) then
		player.mgd.callback = keys.callback
		player.mgd.callback_data = keys.callback_data
	end

	local UnitKV = GetUnitKeyValuesByName(AbilKV.UnitName)

	CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", { state = "active", entIndex = player.mgd:GetEntityIndex(), MaxScale = UnitKV.ModelScale } )
end



------------------------------------------------------
--устанавливаем здание на позицию
------------------------------------------------------

function buildinghelper:AddBuilding(location,playerID,save_dump, build_name)
	local Player = PlayerResource:GetPlayer(playerID)
	local hero = Player:GetAssignedHero()
	local bounds = {}
	local unit

	unit = CreateUnitByName(build_name, location, false, hero, hero, Player:GetTeam())

	if (save_dump == 0) then
		if Player.mgd ~= nil then
			Player.mgd:RemoveSelf()
			Player.mgd = nil
		end
	end

	buildinghelper:RegisterBuilding(unit,Player:GetTeam(),location,hero,playerID)

	--фикс застревания юнитов в здании
	local ent = Entities:FindAllInSphere(location,unit:GetPaddedCollisionRadius())
	for key, value in pairs(ent) do
		if (value.DestroyBuilding == nil) then
			FindClearRandomPositionAroundUnit(value,unit,50)
		end
	end

	return unit
end



------------------------------------------------------
-- Регистрация юнита какая-то хуй знает
------------------------------------------------------

function buildinghelper:RegisterBuilding(unit,team,location,hero,playerID)
	unit:SetOwner(hero)
	unit:SetControllableByPlayer(playerID, true)
	unit.DestroyBuilding = buildinghelper.DestroyBuilding

	local bounds = {}
	bounds = unit:GetBounds()
	bounds =
	{
		Mins = Vector(-64 - 1, -64 - 1, bounds.Mins.z),
		Maxs = Vector(64 + 1, 64 + 1, bounds.Maxs.z)
	}
	unit:SetSize(bounds.Mins,bounds.Maxs)
	unit:SetHullRadius(64*1.3)

	bounds.Mins = bounds.Mins + location
	bounds.Maxs = bounds.Maxs + location
	local c = {Xmin = bounds["Mins"][1],Ymin = bounds["Mins"][2],Xmax = bounds["Maxs"][1],Ymax = bounds["Maxs"][2], EntId = unit:GetEntityIndex()}

	local nettable = CustomNetTables:GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings")
	nettable.length = nettable.length + 1
	nettable[nettable.length] = c
	CustomNetTables:SetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings", nettable)
end



------------------------------------------------------
-- Возвращаем управление в отчку вызова Start_Building
------------------------------------------------------

function buildinghelper:build_command(argv)
	local mgd = PlayerResource:GetPlayer(argv.PlayerID).mgd
	if mgd == nil then return end
	mgd.callback(argv, mgd.callback_data)
end



------------------------------------------------------
-- Удаляем дапм здание
------------------------------------------------------

function buildinghelper:cancel_command( args )
	local Player = PlayerResource:GetPlayer(args.PlayerID)
	CustomGameEventManager:Send_ServerToPlayer(Player, "building_helper_enable", {state = "disable"})
	if (Player.mgd ~= nil) then
		Player.mgd:RemoveSelf()
		Player.mgd = nil
	end
end



------------------------------------------------------
-- check 3x3 place for buildings
------------------------------------------------------

function buildinghelper:CheckPlace(XX,YY,team)
	for x = -1,1,1 do
		for y = -1,1,1 do
			if(not buildinghelper:CheckCell(XX+(x*64) ,YY+(y*64),team)) then
				return false
			end
		end
	end
	return true
end



------------------------------------------------------
-- Проверка клетки на доступность
------------------------------------------------------

function buildinghelper:CheckCell(XX,YY,team)
	local ret = false
	local build_zone = CustomNetTables:GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone")
	local builds = CustomNetTables:GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings")

	for key, zone in pairs(build_zone) do
		if ((zone.Xmax>XX and XX>zone.Xmin) and (zone.Ymax>YY and YY>zone.Ymin)) then
			ret = true
			break
		end
	end

	if (ret==false) then return ret end

	for key, build in pairs(builds) do
		if (key ~= "length" and (build.Xmax>XX and XX>build.Xmin) and (build.Ymax>YY and YY>build.Ymin)) then
			return false
		end
	end

	return ret
end



function buildinghelper:DestroyBuilding(EntId)
	local Ent = EntIndexToHScript(EntId)
	if (Ent.timer ~= nil) then
		Timers:RemoveTimer(Ent.timer)
	end

	utl:RemoveAllAbility(Ent)
	utl:RemoveAllItem(Ent)

	local builds = CustomNetTables:GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings")
	local c = {length = 0}

	for key, value in pairs(builds) do
		if (key ~= "length") and (value.EntId ~= EntId) then
			c.length = c.length + 1
			c[key] = value
		end
	end

	CustomNetTables:SetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings", c)
	Ent:RemoveSelf()
end



function buildinghelper:SnapToGrid(location)
	location.x = 64 * (0.5 + math.floor(location.x/64))
	location.y = 64 * (0.5 + math.floor(location.y/64))
	return location
end



function buildinghelper:InitBuildsZone(zone_name)
	if (zone_name==nil) then
		buildinghelper:InitBuildsZone("stay_alive_buildingzone")
		CustomNetTables:SetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings", {length = 0})
		return
	end

	local ents = Entities:FindAllByName(zone_name)
	local build_zone = {}

	print(zone_name, "active", #ents)

	if (#ents == 0) then
		utl:err("not found build zone",'"'..zone_name..'"')
		return
	end

	for key, ent in pairs(ents) do
		local bounds = ents[key]:GetBounds()
		local Origin = ents[key]:GetAbsOrigin()
		bounds["Mins"] = bounds["Mins"] + Origin
		bounds["Maxs"] = bounds["Maxs"] + Origin
		local c = {
			Xmin = bounds["Mins"][1],
			Ymin = bounds["Mins"][2],
			Xmax = bounds["Maxs"][1],
			Ymax = bounds["Maxs"][2]
		}
		table.insert(build_zone,c)
		ents[key]:RemoveSelf()
		ents[key] = nil
	end
	CustomNetTables:SetTableValue("stay_alive_buildingzone", zone_name, build_zone)
end