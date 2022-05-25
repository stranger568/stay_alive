if (_G.utl == nil) then
	_G.utl = class({})
	CustomGameEventManager:RegisterListener( "Production", Dynamic_Wrap(utl, "Production"))
end

----------Print-----------------------------------------------
function Tprint(...)
	if(... == nil) then print("nil") end
	for key, value in pairs({...}) do
		print(value)
		if (type(value)=="table") then
			_Tprint("",value,0)
		end
	end
end
function _Tprint(pref,data,deep)
	if (deep >= 2) then --deep max
		return
	end
	print(pref.."{")
	for key,value in pairs(data) do
		print(pref.."	"..key,value)
		if (type(value)=="table") then
			_Tprint(pref.."		",value,deep+1)
		end
	end
	print(pref.."}")
end


function Dprint(data)
	print(data)
	if (type(data)=="table") then
		DeepPrintTable(data)
	end
end

function utl:err(...)
	print("[err]",...)
end

function utl:RemoveAllAbility(Ent)
	for i = 0, 5, 1 do
		local abil = Ent:GetAbilityByIndex(i)
		if (abil~=nil) then
		  if (abil.timer ~= nil) then
			Timers:RemoveTimer(abil.timer)
		  end
		  Ent:RemoveAbilityByHandle(abil)
		end
	end
end

function utl:RemoveAllItem(Ent)
	for i = 0, 5, 1 do
		local item = Ent:GetItemInSlot(i)
		if (item ~= nil) then
		  Ent:RemoveItem(item)
		end
	end
end

-- 1 -> stop   production
-- 2 -> start  production
-- 3 -> stop   production special
-- 4 -> start  production special
function utl:Production(key)
	local team = PlayerResource:GetTeam(key.PlayerID)
	local special = nil
	if( key.cmd > 2) then
		special = true
	end
	for __, unit in pairs(cfg.Ent.builds[team]) do
		if (unit:GetPlayerOwnerID() == key.PlayerID) then

			local abil = unit:GetAbilityByIndex(0)
			if ((abil ~= nil) and
				(abil.special == special) and
				(abil:GetAutoCastState()~=((key.cmd % 2) == 1))) then

				abil:OnToggleAutoCast()
				abil:ToggleAutoCast()
			end

		end
	end
end

function utl:KillAll(list)
	if (list == nil) then
		utl:KillAll(cfg.Ent.builds[DOTA_TEAM_GOODGUYS])
		utl:KillAll(cfg.Ent.builds[DOTA_TEAM_BADGUYS])
		utl:KillAll(cfg.Ent.units[DOTA_TEAM_GOODGUYS])
		utl:KillAll(cfg.Ent.units[DOTA_TEAM_BADGUYS])
		utl:KillAll(cfg.Ent.tron[DOTA_TEAM_GOODGUYS])
		utl:KillAll(cfg.Ent.tron[DOTA_TEAM_BADGUYS])
		cfg.Ent.units_death_list[DOTA_TEAM_GOODGUYS]:Clear()
		cfg.Ent.units_death_list[DOTA_TEAM_BADGUYS]:Clear()
		return
	end
	local temp = list
	for key, unit in pairs(temp) do
		temp[key].ForceKillFlag = {}
		temp[key]:ForceKill(false)
		temp[key] = nil
	end
end


----телепортация--героев---на--спавны---
function utl:TP2SpawnAll()
	local heroes = {nil, {}, {}}
	for ID = 0, 9, 1 do
		local player = PlayerResource:GetPlayer(ID)
		if(player ~= nil) then

			local hero = player:GetAssignedHero()
			if(hero ~= nil) then
				heroes[hero:GetTeam()][ID] = hero
			end
		end
	end
	for ID, hero in pairs(heroes[DOTA_TEAM_GOODGUYS]) do
		hero:Interrupt()
		hero:SetAbsOrigin(cfg.player.spawn_point.point[DOTA_TEAM_GOODGUYS][ID+1])
		CenterCameraOnUnit(ID,hero)
	end
	for ID, hero in pairs(heroes[DOTA_TEAM_BADGUYS]) do
		hero:Interrupt()
		hero:SetAbsOrigin(cfg.player.spawn_point.point[DOTA_TEAM_BADGUYS][ID+1])
		CenterCameraOnUnit(ID,hero)
	end
end

function utl:InterraptAll(list)
	if (list == nil) then
		utl:InterraptAll(cfg.Ent.builds[DOTA_TEAM_GOODGUYS])
		utl:InterraptAll(cfg.Ent.builds[DOTA_TEAM_BADGUYS])
		utl:InterraptAll(cfg.Ent.units[DOTA_TEAM_GOODGUYS])
		utl:InterraptAll(cfg.Ent.units[DOTA_TEAM_BADGUYS])
		utl:InterraptAll(cfg.Ent.heroes[DOTA_TEAM_GOODGUYS])
		utl:InterraptAll(cfg.Ent.heroes[DOTA_TEAM_BADGUYS])
		return
	end
	for key, ent in pairs(list) do
		ent:Interrupt()
		--print("Interrupt",ent:GetName())
	end
end

function utl:SetAbilityFromKV(unit,KV)
	local KV = KV[unit:GetName()]
	for i = 0, 25, 1 do
		local abb = unit:GetAbilityByIndex(i)
		if (abb ~= nil) then
			unit:RemoveAbilityByHandle(abb)
		end
	end

	if(KV.Abilitys == nil) then return end

	for i = 1, 25, 1 do
		local abb = KV.Abilitys["Ability"..i]
		if(abb ~= "" and abb ~= nil) then
			local abil = unit:AddAbility(abb)
			if (abil ~= nil) then
				abil:SetLevel(1)
			end
		end
	end
end


function utl:TableSize(table)

	local count = 0
	for k, v in pairs(table) do
		count = count + 1
	end

	return count
end

function utl:TableAt(table, _i)
	local i = 0
	for key, value in pairs(table) do
		i = i + 1
		if(_i == i) then
			return value
		end
	end
	return nil
end

function table.copy(t, deep, seen)
	seen = seen or {}
	if t == nil then return nil end
	if seen[t] then return seen[t] end

	local nt = {}
	for k, v in pairs(t) do
		if deep and type(v) == 'table' then
			nt[k] = table.copy(v, deep, seen)
		else
			nt[k] = v
		end
	end
	setmetatable(nt, table.copy(getmetatable(t), deep, seen))
	seen[t] = nt
	return nt
end

function utl:Shuffle_Key(tbl)

	local temp = {}
	for key, value in pairs(tbl) do
		table.insert(temp, key)
	end

	if (#temp == 1) then return temp end

	for i = 1, #temp, 1 do
		local a = RandomInt(1, #temp)
		local b = RandomInt(1, #temp)
		temp[a], temp[b] = temp[b], temp[a]
	end

	return temp
end

function utl:Shuffle_Value(tbl)

	local temp = {}
	for key, value in pairs(tbl) do
		table.insert(temp, value)
	end


	for i = 1, #temp, 1 do
		local a = RandomInt(1, #temp)
		local b = RandomInt(1, #temp)
		temp[a], temp[b] = temp[b], temp[a]
	end

	return temp
end
------------SOUND-----------------------------------
function utl:EmitSoundOnClient(mSoundName, player)
	CustomGameEventManager:Send_ServerToPlayer(player, "EmitSound", {mSoundName})
end

function utl:split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function utl:DisplayError(playerID, message)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "CreateIngameErrorMessage", {message=message})
    end
end