local function playMugshot()
    local ped = PlayerPedId()
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camPos = Config.Locations.mugshotCam

    Punish.teleport(Config.Locations.mugshot)
    FreezeEntityPosition(ped, true)
    ExecuteCommand('e ' .. Config.Emotes.mugshot)

    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    SetCamRot(cam, 0.0, 0.0, 0.0, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    Wait(3000)
    TriggerScreenblurFadeIn(1.0)
    Wait(500)
    TriggerScreenblurFadeOut(1.0)
    Wait(2000)

    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cam, false)
    FreezeEntityPosition(ped, false)
    ExecuteCommand('e ' .. Config.Emotes.reset)
end

local function startJail(units, mugshot)
    Punish.jail.active = true
    Punish.jail.units = units
    Punish.jail.total = units
    Punish.applyClothes('jail')

    if mugshot then
        Punish.locked = true
        playMugshot()
        Punish.locked = false
    end

    Punish.teleport(Config.Locations.jailEnter)
    Punish.notify(Locale('notify.jail_started', units), 'error')
    Punish.sendHud()
end

RegisterNetEvent('punish:jail:start', startJail)

RegisterNetEvent('punish:jail:update', function(units)
    if not Punish.jail.active then return end
    Punish.jail.units = units
    Punish.sendHud()
end)

RegisterNetEvent('punish:jail:release', function()
    Punish.jail.active = false
    Punish.jail.units = 0
    Punish.jail.total = 0
    Punish.teleport(Config.Locations.jailRelease)
    Punish.resetClothes()
    Punish.notify(Locale('notify.jail_released_player'), 'success')
    Punish.sendHud()
end)

local detailsOpen = false

local function openJailDetails()
    if detailsOpen then return end
    ESX.TriggerServerCallback('punish:ownJail', function(data)
        if not data then
            return Punish.notify(Locale('jail.details_none'), 'inform')
        end
        detailsOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'details',
            data = {
                units = data.units,
                reason = data.reason or '-',
                judge = data.judge or '-',
                date = data.date or '-',
            },
            strings = GetLocaleStrings(),
        })
    end)
end

RegisterNUICallback('detailsClosed', function(_, cb)
    detailsOpen = false
    cb('ok')
end)

CreateThread(function()
    while true do
        if Punish.locked then
            DisableAllControlActions(0)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local spot = Config.Locations.jailDetails
        local dist = #(coords - vector3(spot.x, spot.y, spot.z))

        if dist < Config.MarkerDistance then
            sleep = 0
            DrawMarker(32, spot.x, spot.y, spot.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 90, 140, 255, 140, false, true, 2, nil, nil, false)
            if dist < Config.PromptDistance then
                ESX.ShowHelpNotification(Locale('jail.details_prompt'))
                if IsControlJustReleased(0, 38) then
                    openJailDetails()
                end
            end
        end

        Wait(sleep)
    end
end)
