ESX = nil
local GUI                     = {}
local HasAlreadyEnteredMarker = false
local LastZone                = nil

Config = {
    charAnims = {
        {isAnim = true, dic = "anim@amb@nightclub@peds@", name = "rcmme_amanda1_stand_loop_cop"},
        {isAnim = false, h = 359.1, dic = "WORLD_HUMAN_LEANING"},
        {isAnim = false, dic = "WORLD_HUMAN_SMOKING_POT"},
        {isAnim = false, dic = "WORLD_HUMAN_PARTYING"},
        {isAnim = false, dic = "WORLD_HUMAN_MUSCLE_FLEX"},
        {isAnim = true,  dic = "anim@amb@casino@hangout@ped_male@stand@02b@idles", name = "idle_a"}
    }
}

HiddenCoords = {x = -797.652, y =19.72931, z = -46.68998, h = 174.64}

createdChars = {}

CurrentRequestId          = 0
ServerCallbacks           = {}
TimeoutCallbacks          = {}

RegisterNetEvent('neey:serverCallback')
AddEventHandler('neey:serverCallback', function(requestId, ...)
	ServerCallbacks[requestId](...)
	ServerCallbacks[requestId] = nil
end)

TriggerServerCallback = function(name, cb, ...)
	ServerCallbacks[CurrentRequestId] = cb

	TriggerServerEvent('neey:triggerServerCallback', name, CurrentRequestId, ...)

	if CurrentRequestId < 65535 then
		CurrentRequestId = CurrentRequestId + 1
	else
		CurrentRequestId = 0
	end
end

RegisterNUICallback('SwitchCharacter', function(data)
    for k,v in pairs(createdChars) do
        DeleteEntity(v.ped)
        createdChars = {}
    end
    CreatePeds(data.charid)
end)

local cam = nil

RegisterNUICallback('CharacterChosen', function(data)
    for k,v in pairs(createdChars) do
        DeleteEntity(v.ped)
        createdChars = {}
    end
    SetNuiFocus(false, false)
    if data.ischar == true then
        TriggerServerEvent('neey_characters:selectCharacter', data.charid)
    else
        SetEntityCoords(GetPlayerPed(-1), -1042.28, -2745.42, 20.40)
        TriggerServerEvent('neey_characters:selectCharacter', data.charid, true)
    end
    SetEntityVisible(GetPlayerPed(-1), true)
    RenderScriptCams(false, true, 500, true, true)
end)

RegisterNetEvent('neey_characters:menuOpen')
AddEventHandler('neey_characters:menuOpen', function(limit, chars)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openui",
        characters = chars,
        limit = limit,
    })
    menuOpened()
end)


function menuOpened()
    DoScreenFadeIn(10)

    FreezeEntityPosition(GetPlayerPed(-1), true)
    SetEntityCoords(PlayerPedId(), HiddenCoords.x, HiddenCoords.y, HiddenCoords.z)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(cam, -797.652, 19.72931, -45.68998 )
	SetCamRot(cam, 5.0, 0.0, 540.0)
    SetCamFov(cam, 42.0)
    



    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
    SetEntityVisible(GetPlayerPed(-1), false)
    local interior = GetInteriorAtCoords(-797.652, 19.72931, -46.68998)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Citizen.Wait(1000)
    end
    CreatePeds(1)
end


function neeyRequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function CreatePeds(i)
    Citizen.CreateThread(
        function()
            Citizen.Wait(1)
            TriggerServerCallback(
                "neey_characters:GetPlayerData",
                function(Player)
                    if Player ~= nil then
                        local PlayerSkin = json.decode(Player.skin)
                        DeleteEntity(charPed)
                        ClearPedTasks(charPed)
                        ClearPedTasksImmediately(charPed)

                        local model
                        if PlayerSkin.sex == tonumber(0) then
                            model = "mp_m_freemode_01"
                        else
                            model = "mp_f_freemode_01"
                        end
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Citizen.Wait(0)
                        end
                        local charPed = CreatePed(3, model, -797.2302, 17.04202, -46.69, 359.1, false, true)
                        local random = math.random(1, #Config.charAnims)

                        if Config.charAnims[tonumber(random)].isAnim == true then
                            neeyRequestAnimDict(
                                Config.charAnims[tonumber(random)].dic,
                                function()
                                    TaskPlayAnim(
                                        charPed,
                                        Config.charAnims[tonumber(random)].dic,
                                        Config.charAnims[tonumber(random)].name,
                                        2.0,
                                        2.0,
                                        -1,
                                        33,
                                        0,
                                        false,
                                        false,
                                        false
                                    )
                                end
                            )
                        else
                            TaskStartScenarioInPlace(charPed, Config.charAnims[tonumber(random)].dic, 0, true)
                        end

                        ApplySkinForPed(charPed, PlayerSkin)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        FreezeEntityPosition(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        table.insert(
                            createdChars,
                            {
                                ped = charPed
                            }
                        )
                    else
                        DeleteEntity(charPed)
                        local model = "mp_m_freemode_01"
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Citizen.Wait(0)
                        end
                        local charPed = CreatePed(3, model, -797.2302, 17.04202, -46.69, 359.1, false, true)
                        SetEntityAlpha(charPed, 100)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        FreezeEntityPosition(charPed, true)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        table.insert(
                            createdChars,
                            {
                                ped = charPed
                            }
                        )
                    end
                end,
                i
            )
        end
    )
end

function ApplySkinForPed(char ,Character)
    SetPedHeadBlendData(char, Character['face'], Character['face'],         Character['face'], Character['skin'], Character['skin'], Character['skin'], 1.0, 1.0, 1.0, true)
    SetPedComponentVariation(char, 8,       Character['tshirt_1'],          Character['tshirt_2'], 2)	
    SetPedComponentVariation(char, 11,      Character['torso_1'],	        Character['torso_2'], 2)					
    SetPedComponentVariation(char, 3,       Character['arms'],	            Character['arms_2'], 2)		
    SetPedComponentVariation(char, 10,      Character['decals_1'],          Character['decals_2'], 2)	
    SetPedComponentVariation(char, 4,       Character['pants_1'],	        Character['pants_2'], 2)	
    SetPedComponentVariation(char, 6,       Character['shoes_1'],	        Character['shoes_2'], 2)	
    SetPedComponentVariation(char, 1,       Character['mask_1'],	        Character['mask_2'], 2)		
    SetPedComponentVariation(char, 9,       Character['bproof_1'],          Character['bproof_2'], 2)					
    SetPedComponentVariation(char, 7,       Character['chain_1'],	        Character['chain_2'], 2)	
    SetPedComponentVariation(char, 5,       Character['bags_1'],	        Character['bags_2'], 2)
    SetPedComponentVariation(char, 2,       Character['hair_1'],            Character['hair_2'], 2)
	SetPedHairColor			(char,			Character['hair_color_1'],		Character['hair_color_2'])					-- Hair Color
	SetPedHeadOverlay		(char, 3,		Character['age_1'],				(Character['age_2'] / 10) + 0.0)			-- Age + opacity
	SetPedHeadOverlay		(char, 0,		Character['blemishes_1'],		(Character['blemishes_2'] / 10) + 0.0)		-- Blemishes + opacity
	SetPedHeadOverlay		(char, 1,		Character['beard_1'],			(Character['beard_2'] / 10) + 0.0)			-- Beard + opacity
	SetPedEyeColor			(char,			Character['eye_color'], 0, 1)												-- Eyes color
	SetPedHeadOverlay		(char, 2,		Character['eyebrows_1'],		(Character['eyebrows_2'] / 10) + 0.0)		-- Eyebrows + opacity
	SetPedHeadOverlay		(char, 4,		Character['makeup_1'],			(Character['makeup_2'] / 10) + 0.0)			-- Makeup + opacity
	SetPedHeadOverlay		(char, 8,		Character['lipstick_1'],		(Character['lipstick_2'] / 10) + 0.0)		-- Lipstick + opacity
	SetPedComponentVariation(char, 2,		Character['hair_1'],			Character['hair_2'], 2)						-- Hair
	SetPedHeadOverlayColor	(char, 1, 1,	Character['beard_3'],			Character['beard_4'])						-- Beard Color
	SetPedHeadOverlayColor	(char, 2, 1,	Character['eyebrows_3'],		Character['eyebrows_4'])					-- Eyebrows Color
	SetPedHeadOverlayColor	(char, 4, 1,	Character['makeup_3'],			Character['makeup_4'])						-- Makeup Color
	SetPedHeadOverlayColor	(char, 8, 1,	Character['lipstick_3'],		Character['lipstick_4'])					-- Lipstick Color
	SetPedHeadOverlay		(char, 5,		Character['blush_1'],			(Character['blush_2'] / 10) + 0.0)			-- Blush + opacity
	SetPedHeadOverlayColor	(char, 5, 2,	Character['blush_3'])														-- Blush Color
	SetPedHeadOverlay		(char, 6,		Character['complexion_1'],		(Character['complexion_2'] / 10) + 0.0)		-- Complexion + opacity
	SetPedHeadOverlay		(char, 7,		Character['sun_1'],				(Character['sun_2'] / 10) + 0.0)			-- Sun Damage + opacity
	SetPedHeadOverlay		(char, 9,		Character['moles_1'],			(Character['moles_2'] / 10) + 0.0)			-- Moles/Freckles + opacity
	SetPedHeadOverlay		(char, 10,		Character['chest_1'],			(Character['chest_2'] / 10) + 0.0)			-- Chest Hair + opacity
	SetPedHeadOverlayColor	(char, 10, 1,	Character['chest_3'])														-- Torso Color
	SetPedHeadOverlay		(char, 11,		Character['bodyb_1'],			(Character['bodyb_2'] / 10) + 0.0)			-- Body Blemishes + opacity

    if Character['helmet_1'] == -1 then
        ClearPedProp(char, 0)
    else
        SetPedPropIndex(char, 0, Character['helmet_1'],    Character['helmet_2'], 2)
    end
    
    if Character['glasses_1'] == -1 then
        ClearPedProp(char, 1)
    else
        SetPedPropIndex(char, 1, Character['glasses_1'],   Character['glasses_2'], 2)
    end
    
    if Character['watches_1'] == -1 then
        ClearPedProp(char, 6)
    else
        SetPedPropIndex(char, 6, Character['watches_1'],   Character['watches_2'], 2)
    end
    
    if Character['bracelets_1'] == -1 then
        ClearPedProp(char,	7)
    else
        SetPedPropIndex(char, 7, Character['bracelets_1'], Character['bracelets_2'], 2)
    end
end