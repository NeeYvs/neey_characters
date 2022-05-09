ServerCallbacks = {}

RegisterServerEvent('neey:triggerServerCallback')
AddEventHandler('neey:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	TriggerServerCallback(name, requestID, playerId, function(...)
		TriggerClientEvent('neey:serverCallback', playerId, requestId, ...)
	end, ...)
end)

RegisterServerCallback = function(name, cb)
	ServerCallbacks[name] = cb
end

TriggerServerCallback = function(name, requestId, source, cb, ...)
	if ServerCallbacks[name] ~= nil then
		ServerCallbacks[name](source, cb, ...)
	else
		print(('[esx_kashacters] [^3WARNING^7] Server callback "%s" does not exist. Make sure that the server sided file really is loading, an error in that file might cause it to not load.'):format(name))
	end
end

RegisterCommand('changePostac', function(source)
    TriggerEvent('neey_characters:loadChars', source, GetPlayerIdentifiers(source)[1])
end)

RegisterServerEvent("neey_characters:loadChars")
AddEventHandler('neey_characters:loadChars', function(source, identifier)
    local limit = MySQLAsyncExecute("SELECT `limit` FROM `users` WHERE `identifier` = '" .. identifier .. "'", {})
    local plimit = tonumber(limit[1].limit)
    if plimit ~= nil then

        local Characters = GetPlayerCharacters(identifier)
        TriggerClientEvent('neey_characters:menuOpen', source, plimit, Characters)
    else
        local Characters = GetPlayerCharacters(identifier)
        TriggerClientEvent('neey_characters:menuOpen', source, 1, Characters)
    end
end)

function GetIdentifierWithoutSteam(identifier)
    return string.gsub(identifier, "steam:", "")
end

function GetPlayerCharacters(id)
    local identifier = GetIdentifierWithoutSteam(id)
    local Chars = MySQLAsyncExecute("SELECT * FROM `characters` WHERE identifier LIKE '%"..identifier .."%'", {})
    return Chars
end

function MySQLAsyncExecute(query, rdata)
    local IsBusy = true
    local result = nil
    MySQL.Async.fetchAll(query, rdata, function(data)
        result = data
        IsBusy = false
    end)
    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

RegisterServerEvent("neey_characters:selectCharacter")
AddEventHandler('neey_characters:selectCharacter', function(value, create)
    local identifier = GetIdentifierWithoutSteam(GetPlayerIdentifiers(source)[1])
    local hex = "Char".. value ..":" .. identifier
    if create ~= nil then
        TriggerClientEvent('esx_identity:showRegisterIdentity', source, value)
        local Check = MySQLAsyncExecute("SELECT * FROM `characters` WHERE identifier = '"..identifier .."'", {})
        if Check[1] ~= nil then
            TriggerClientEvent('esx_identity:showRegisterIdentity', source, value)
        else
            MySQL.Async.execute("INSERT INTO `characters` (`identifier`) VALUES ('"..hex.."')", {})
        end
    else
        TriggerEvent('esx:loadPlayer', hex, source)
    end
end)

RegisterServerCallback('neey_characters:GetPlayerData', function(source, cb, value)
    if value == nil then
        cb(nil)
    else
        local identifier = GetIdentifierWithoutSteam(GetPlayerIdentifiers(source)[1])
        local Chars = MySQLAsyncExecute("SELECT * FROM `characters` WHERE identifier = 'Char" .. value ..":" .. identifier .. "'" , {})
        cb(Chars[1])
    end
end)
