ESX = exports['es_extended']:getSharedObject()

Punish = {
    jail = { active = false, units = 0, total = 0 },
    comserv = { active = false, hours = 0, total = 0, trash = {} },
    admin = { active = false, minutes = 0, total = 0 },
    afkSeconds = 0,
    lastPos = nil,
    tickCounter = 0,
    locked = false,
}

local typeColors = {
    success = '~g~',
    error = '~r~',
    warning = '~y~',
    inform = '~b~',
}

function Punish.notify(description, ntype)
    ESX.ShowNotification((typeColors[ntype or 'inform'] or '') .. description)
end

function Punish.applyClothes(set)
    TriggerEvent('skinchanger:getSkin', function(skin)
        local gender = skin.sex == 0 and 'male' or 'female'
        TriggerEvent('skinchanger:loadClothes', skin, Config.Clothes[set][gender])
    end)
end

function Punish.resetClothes()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)
end

function Punish.teleport(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
end

function Punish.sendHud()
    local data = nil

    if Punish.jail.active then
        data = {
            theme = 'jail',
            title = Locale('hud.jail'),
            value = Punish.jail.units,
            total = Punish.jail.total,
            unit = Locale('hud.unit_units'),
            icon = 'lock',
        }
    elseif Punish.comserv.active then
        data = {
            theme = 'comserv',
            title = Locale('hud.comserv'),
            value = Punish.comserv.hours,
            total = Punish.comserv.total,
            unit = Locale('hud.unit_tasks'),
            icon = 'broom',
        }
    elseif Punish.admin.active then
        local afk = Punish.afkSeconds >= Config.AdminJailAfkSeconds
        data = {
            theme = 'admin',
            title = Locale('hud.admin'),
            value = Punish.admin.minutes,
            total = Punish.admin.total,
            unit = Locale('hud.unit_minutes'),
            icon = 'shield',
            afk = afk,
            afkText = Locale('hud.afk'),
        }
    end

    SendNUIMessage({
        action = 'hud',
        show = data ~= nil,
        data = data,
    })
end
