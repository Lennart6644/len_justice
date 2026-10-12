RegisterNetEvent('punish:client:open', function(mode, perms, limits)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        mode = mode,
        perms = perms,
        limits = limits,
        strings = GetLocaleStrings(),
    })
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/punish', Locale('chat.punish'))
    TriggerEvent('chat:addSuggestion', '/adminjail', Locale('chat.adminjail'))
    TriggerEvent('chat:addSuggestion', '/quickpunish', Locale('chat.quickpunish'), {
        { name = 'ID', help = Locale('chat.param_id') },
        { name = 'jail|comserv', help = Locale('chat.param_type') },
        { name = 'Anzahl', help = Locale('chat.param_amount') },
        { name = 'Grund', help = Locale('chat.param_reason') },
    })
    TriggerEvent('chat:addSuggestion', '/quickrelease', Locale('chat.quickrelease'), {
        { name = 'ID', help = Locale('chat.param_id') },
        { name = 'jail|comserv', help = Locale('chat.param_type') },
    })
end)
