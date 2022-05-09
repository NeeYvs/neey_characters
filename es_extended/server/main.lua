local charset = {}

for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string.random(length)
  math.randomseed(os.time())

  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

ItemsList = {}
local Weapons = {}

for name,item in pairs(Config.WeaponsList) do
	Weapons[GetHashKey(name)] = item
	ItemsList[item.item] = name
end

function IsWeapon(name)
	if ItemsList[name] then
	return ItemsList[name]
  end
  
	return false
end

CreateThread(function()
	local resourcesStopped = {}

	if ESX.Table.SizeOf(resourcesStopped) > 0 then
		local allStoppedResources = ''

		for resourceName,reason in pairs(resourcesStopped) do
			allStoppedResources = ('%s\n- ^3%s^7, %s'):format(allStoppedResources, resourceName, reason)
		end

	end
end)

RegisterNetEvent('esx:onPlayerJoined')
AddEventHandler('esx:onPlayerJoined', function()
	if not ESX.Players[source] then
		onPlayerJoined(source)
	end
end)

function onPlayerJoined(playerId)
	local identifier

	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'steam:') then
			identifier = v
			break
		end
	end

	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			DropPlayer(playerId, ('there was an error loading your character!\nError code: identifier-active-ingame\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s'):format(identifier))
		else
			MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
				['@identifier'] = identifier
			}, function(result)
				if result then
					Citizen.Wait(1000)
					TriggerEvent('neey_characters:loadChars', playerId, identifier)
				else
					local accounts = {}

					for account,money in pairs(Config.StartingAccountMoney) do
						accounts[account] = money
					end

					MySQL.Async.execute('INSERT INTO users (ip, identifier) VALUES (@ip, @identifier)', {
						['@identifier'] = identifier,
						['@ip'] = GetPlayerEndpoint(playerId)
					}, function(rowsChanged)
						Citizen.Wait(1000)
						TriggerEvent('neey_characters:loadChars', playerId, identifier)
					end)
				end
			end)
		end
	else
		DropPlayer(playerId, 'there was an error loading your character!\nError code: identifier-missing-ingame\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.')
	end
end

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
	deferrals.defer()
	local playerId, nick, identifier = source, true
	Citizen.Wait(100)
	
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'steam:') then
			identifier = v
			break
		end
	end
	
	if GetPlayerName(playerId) ~= nil then
		local count = 0
		local nameLength = string.len(GetPlayerName(playerId))
		for i in GetPlayerName(playerId):gmatch('[aąbcćdeęfghijklłmnoópqrsśtuvwxyzżźäöAĄBCĆDEĘFGHIJKLŁMNOÓPQRSŚTUVWXYZŻŹÄÖ0123456789 |._-]') do
			count = count + 1
		end
		if count ~= nameLength then
			nick = false
		end
	else
		nick = false
	end
	
	if identifier then
		if nick then
			if ESX.GetPlayerFromIdentifier(identifier) then
				deferrals.done(('There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s'):format(identifier))
			else
				deferrals.done()
			end	
		else
			deferrals.done('Twój nick posiada niedozwolone znaki\nDozwolone znaki na naszym serwerze: [aąbcćdeęfghijklłmnoópqrsśtuvwxyzżźäöAĄBCĆDEĘFGHIJKLŁMNOÓPQRSŚTUVWXYZŻŹÄÖ0123456789 |._-]')
		end
	else
		deferrals.done('There was an error loading your character!\nError code: identifier-missing\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.')
	end
end)

RegisterNetEvent('esx:loadPlayer')
AddEventHandler('esx:loadPlayer', function(identifier, source)
	loadESXPlayer(identifier, source)
end)

function loadESXPlayer(identifier, playerId)
	local tasks = {}

	local userData = {
		accounts = {},
		inventory = {},
		job = {},
		character    = {},
		playerName = GetPlayerName(playerId),
		job2    = {},
		loadout = {}
	}
	table.insert(tasks, function(cb)
		MySQL.Async.fetchAll('SELECT * FROM characters WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			local job, grade, jobObject, gradeObject = result[1].job, tostring(result[1].job_grade)
			local job2, job2grade = result[1].job2, tostring(result[1].job2_grade)
			local foundAccounts, foundItems = {}, {}

			--Characters 
			
			if result[1].firstname and result[1].lastname ~= '' then
			    userData.character.firstname 	= result[1].firstname
                userData.character.lastname 	= result[1].lastname
                userData.character.dateofbirth  = result[1].dateofbirth
                userData.character.sex			= result[1].sex
                userData.character.status 		= result[1].status
                userData.character.phone_number = result[1].phone_number
                userData.character.tattoos 		= result[1].tattoos
			end
			
			-- Accounts
			if result[1].accounts and result[1].accounts ~= '' then
				local accounts = json.decode(result[1].accounts)

				for account,money in pairs(accounts) do
					foundAccounts[account] = money
				end
			end

			for account,label in pairs(Config.Accounts) do
				table.insert(userData.accounts, {
					name = account,
					money = foundAccounts[account] or Config.StartingAccountMoney[account] or 0,
					label = label
				})
			end

			
			if ESX.DoesJobExist(job2, job2grade) then
				local jobObject, gradeObject = ESX.Jobs[job2], ESX.Jobs[job2].grades[job2grade]

				userData.job2 = {}

				userData.job2.id    = jobObject.id
				userData.job2.name  = jobObject.name
				userData.job2.label = jobObject.label

				userData.job2.grade        = tonumber(job2grade)
				userData.job2.grade_name   = gradeObject.name
				userData.job2.grade_label  = gradeObject.label
				userData.job2.grade_salary = gradeObject.salary

				userData.job2.skin_male    = {}
				userData.job2.skin_female  = {}

				if gradeObject.skin_male ~= nil then
					userData.job2.skin_male = json.decode(gradeObject.skin_male)
				end
	
				if gradeObject.skin_female ~= nil then
					userData.job2.skin_female = json.decode(gradeObject.skin_female)
				end

			else
				local job2, job2grade = 'unemployed', '0'
				local jobObject, gradeObject = ESX.Jobs[job2], ESX.Jobs[job2].grades[job2grade]

				userData.job2 = {}

				userData.job2.id    = jobObject.id
				userData.job2.name  = jobObject.name
				userData.job2.label = jobObject.label
	
				userData.job2.grade        = tonumber(job2grade)
				userData.job2.grade_name   = gradeObject.name
				userData.job2.grade_label  = gradeObject.label
				userData.job2.grade_salary = gradeObject.salary
	
				userData.job2.skin_male    = {}
				userData.job2.skin_female  = {}
			end
			-- Job
			if ESX.DoesJobExist(job, grade) then
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			else
				job, grade = 'unemployed', '0'
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			end

			userData.job.id = jobObject.id
			userData.job.name = jobObject.name
			userData.job.label = jobObject.label

			userData.job.grade = tonumber(grade)
			userData.job.grade_name = gradeObject.name
			userData.job.grade_label = gradeObject.label
			userData.job.grade_salary = gradeObject.salary

			userData.job.skin_male = {}
			userData.job.skin_female = {}

			if gradeObject.skin_male then userData.job.skin_male = json.decode(gradeObject.skin_male) end
			if gradeObject.skin_female then userData.job.skin_female = json.decode(gradeObject.skin_female) end


			
			-- Inventory
			if result[1].inventory and result[1].inventory ~= '' then
				local inventory = json.decode(result[1].inventory)

				for name, data in pairs(inventory) do
					local item = ESX.Items[name]
					if not IsWeapon(item) then
						if item then
							if data.slot then
								foundItems[name] = { count = data.count, slot = data.slot }
							else
								foundItems[name] = { count = data.count }
							end
						end
					end
				end
			end

			if result[1].loadout ~= nil then
				userData.loadout = json.decode(result[1].loadout)

				for k,v in ipairs(userData.loadout) do
					if v.components == nil then
						v.components = {}
					end
				end
			end

			for name,item in pairs(ESX.Items) do
				local count = 0
				local slot = false
				local serialNumber = nil

				if foundItems[name] then
					if foundItems[name].count then
						count = foundItems[name].count
					end

					if foundItems[name].slot then
						slot = foundItems[name].slot
					end
				end

				table.insert(userData.inventory, {
					name = name,
					count = count,
					slot = slot,
					label = item.label,
					limit = item.limit,
					usable = ESX.UsableItemsCallbacks[name] ~= nil,
					rare = item.rare,
					canRemove = item.canRemove
				})
			end

			table.sort(userData.inventory, function(a, b)
				return a.label < b.label
			end)

			-- Group
			if result[1].group then
				userData.group = result[1].group
			else
				userData.group = 'user'
			end

			-- Position
			if result[1].position and result[1].position ~= '' then
				userData.coords = json.decode(result[1].position)
			else
				userData.coords = {x = -1042.28, y = -2745.42, z = 20.40, heading = 205.8}
			end

			cb()
		end)
	end)

	Async.parallel(tasks, function(results)
		local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.job, userData.job2, userData.playerName, userData.coords, userData.character, userData.loadout)
		ESX.Players[playerId] = xPlayer
		TriggerEvent('esx:playerLoaded', playerId, xPlayer)

		xPlayer.triggerEvent('esx:playerLoaded', {
			accounts = xPlayer.getAccounts(),
			coords = xPlayer.getCoords(),
			identifier = xPlayer.getIdentifier(),
			inventory = xPlayer.getInventory(),
			job = xPlayer.getJob(),
			money = xPlayer.getMoney(),
			character	 = xPlayer.getCharacter(),
			job2	 = xPlayer.getjob2(),
			loadout      = xPlayer.getLoadout(),
		})

		xPlayer.triggerEvent('esx:registerSuggestions', ESX.RegisteredCommands)
	end)
end

AddEventHandler('chatMessage', function(playerId, author, message)
	if message:sub(1, 1) == '/' and playerId > 0 then
		CancelEvent()
		local commandName = message:sub(1):gmatch("%w+")()
	end
end)

AddEventHandler('playerDropped', function(reason)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer then
		TriggerEvent('esx:playerDropped', playerId, reason)

		ESX.SavePlayer(xPlayer, function()
			ESX.Players[playerId] = nil
		end)
	end
end)

RegisterServerEvent('esx:updateLoadout')
AddEventHandler('esx:updateLoadout', function(loadout)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.loadout = loadout
end)

RegisterNetEvent('esx:updateCoords')
AddEventHandler('esx:updateCoords', function(coords)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateCoords(coords)
	end
end)

RegisterServerEvent('esx:addToSlot')
AddEventHandler('esx:addToSlot', function(slot, data, type, serialNumber)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addToSlot(slot, data.name, type, serialNumber)
end)

RegisterNetEvent('esx:updateWeaponAmmo')
AddEventHandler('esx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)

RegisterNetEvent('esx:gitestveInventoryItem')
AddEventHandler('esx:gitestveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = ESX.GetPlayerFromId(playerId)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		local targetItem = targetXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then
			if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
				sourceXPlayer.showNotification(_U('ex_inv_lim', targetXPlayer.source))
			else				
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.addInventoryItem   (itemName, itemCount)

				sourceXPlayer.showNotification(_U('gave_item', itemCount, sourceItem.label, targetXPlayer.source))
				targetXPlayer.showNotification(_U('received_item', itemCount, sourceItem.label, sourceXPlayer.source))
			end
		else
			sourceXPlayer.showNotification(_U('imp_invalid_quantity'))
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)

			sourceXPlayer.showNotification(_U('gave_account_money', ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], targetXPlayer.source))
			targetXPlayer.showNotification(_U('received_account_money', ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], sourceXPlayer.source))
		else
			sourceXPlayer.showNotification(_U('imp_invalid_amount'))
		end
	elseif type == 'item_weapon' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponLabel = ESX.GetWeaponLabel(itemName)

			if not targetXPlayer.hasWeapon(itemName) then
				local _, weapon = sourceXPlayer.getWeapon(itemName)
				local _, weaponObject = ESX.GetWeapon(itemName)
				
				if itemCount ~= nil then
					itemCount = itemCount
				else
					itemCount = 1
				end

				sourceXPlayer.removeWeapon(itemName, itemCount)
				targetXPlayer.addWeapon(itemName, itemCount)

				if weaponObject.ammo and itemCount > 0 then
					local ammoLabel = weaponObject.ammo.label
					sourceXPlayer.showNotification(_U('gave_weapon_withammo', weaponLabel, itemCount, ammoLabel, targetXPlayer.source))
					targetXPlayer.showNotification(_U('received_weapon_withammo', weaponLabel, itemCount, ammoLabel, sourceXPlayer.source))
				else
					sourceXPlayer.showNotification(_U('gave_weapon', weaponLabel, targetXPlayer.source))
					targetXPlayer.showNotification(_U('received_weapon', weaponLabel, sourceXPlayer.source))
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_hasalready', targetXPlayer.source, weaponLabel))
				targetXPlayer.showNotification(_U('received_weapon_hasalready', sourceXPlayer.source, weaponLabel))
			end
		end
	elseif type == 'item_ammo' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)

			if targetXPlayer.hasWeapon(itemName) then
				local _, weaponObject = ESX.GetWeapon(itemName)

				if weaponObject.ammo then
					local ammoLabel = weaponObject.ammo.label

					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)

						TriggerClientEvent('sendProximityMessageDo', -1, playerId, playerId, "przekazał "..itemCount.." naboi do broni "..weapon.label.."")
						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.source))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.source))
					end
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.source))
				targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.source, weapon.label))
			end
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)

	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_quantity'))
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showNotification(_U('imp_invalid_quantity'))
			else
				xPlayer.removeInventoryItem(itemName, itemCount)
				xPlayer.showNotification(_U('threw_standard', itemCount, xItem.label))
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_amount'))
		else
			local account = xPlayer.getAccount(itemName)

			if (itemCount > account.money or account.money < 1) then
				xPlayer.showNotification(_U('imp_invalid_amount'))
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
				xPlayer.showNotification(_U('threw_account', ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
			end
		end
	elseif type == 'item_weapon' then
		print(xPlayer.hasWeapon(itemName))
		if xPlayer.hasWeapon(itemName) then
			local _, weapon = xPlayer.getWeapon(itemName)

			xPlayer.removeWeapon(itemName)
			
			xPlayer.showNotification(_U('threw_weapon', weapon.label))
		end
	end
end)

RegisterNetEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local count = xPlayer.getInventoryItem(itemName).count

	if count > 0 then
		ESX.UseItem(source, itemName)
	else
		xPlayer.showNotification(_U('act_imp'))
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		job2 	 = xPlayer.getjob2(),
		money        = xPlayer.getMoney(), 
		loadout = xPlayer.getLoadout()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		job2 	 = xPlayer.getjob2(),
		money        = xPlayer.getMoney(),
		loadout = xPlayer.getLoadout()
	})
end)

ESX.RegisterServerCallback('esx:getPlayerNames', function(source, cb, players)
	players[source] = nil

	for playerId,v in pairs(players) do
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer then
			players[playerId] = xPlayer.getName()
		else
			players[playerId] = nil
		end
	end

	cb(players)
end)

ESX.StartDBSync()
ESX.StartPayCheck()