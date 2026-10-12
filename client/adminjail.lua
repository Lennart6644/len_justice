RegisterNetEvent('punish:adminjail:start', function(minutes)
    Punish.admin.active = true
    Punish.admin.minutes = minutes
    Punish.admin.total = minutes
    Punish.afkSeconds = 0
    Punish.lastPos = nil
    Punish.tickCounter = 0
    Punish.applyClothes('adminJail')
    Punish.teleport(Config.Locations.jailEnter)
    Punish.sendHud()
end)

RegisterNetEvent('punish:adminjail:update', function(minutes)
    if not Punish.admin.active then return end
    Punish.admin.minutes = minutes
    Punish.sendHud()
end)

RegisterNetEvent('punish:adminjail:release', function(reason)
    Punish.admin.active = false
    Punish.admin.minutes = 0
    Punish.admin.total = 0
    Punish.afkSeconds = 0
    Punish.teleport(Config.Locations.jailRelease)
    Punish.resetClothes()
    Punish.notify(Locale(reason == 'expired' and 'notify.admin_expired' or 'notify.admin_released_player'), 'success')
    Punish.sendHud()
end)

CreateThread(function()
    while true do
        if Punish.admin.active then
            local ped = PlayerPedId()
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 289, true)
            DisableControlAction(0, 167, true)
            if IsPedInAnyVehicle(ped, false) then
                TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if Punish.admin.active then
            local coords = GetEntityCoords(PlayerPedId())
            if Punish.lastPos and #(coords - Punish.lastPos) < 0.5 then
                Punish.afkSeconds = Punish.afkSeconds + 1
            else
                Punish.afkSeconds = 0
            end
            Punish.lastPos = coords

            Punish.tickCounter = Punish.tickCounter + 1
            if Punish.tickCounter >= Config.AdminJailTickSeconds then
                Punish.tickCounter = 0
                TriggerServerEvent('punish:adminjail:tick', Punish.afkSeconds < Config.AdminJailAfkSeconds)
            end

            Punish.sendHud()
        else
            Punish.afkSeconds = 0
            Punish.lastPos = nil
            Punish.tickCounter = 0
        end
    end
end)
