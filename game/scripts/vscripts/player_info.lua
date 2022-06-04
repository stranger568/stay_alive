if PlayerInfo == nil then
	PlayerInfo = class({})
end

PlayerInfo.PLAYERS = {}

function PlayerInfo:RegisterPlayerInfo( player_id )
	-- Проверка на даунов
    if not PlayerResource:IsValidPlayerID(player_id) then return end
    if tostring( PlayerResource:GetSteamAccountID( player_id ) ) == nil then return end
    if PlayerResource:GetSteamAccountID( player_id ) == 0 then return end
    if PlayerResource:GetSteamAccountID( player_id ) == "0" then return end

	-- Регистрируем нужную информацию
	local pinfo = PlayerInfo.PLAYERS[ player_id ] or {
		steamid = PlayerResource:GetSteamAccountID( player_id ),
	}
	
	PlayerInfo.PLAYERS[ player_id ] = pinfo
	return pinfo
end