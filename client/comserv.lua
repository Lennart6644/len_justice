local busy = false

local function removeTrash(index)
    local item = Punish.comserv.trash[index]
    if not item then return end
    if DoesBlipExist(item.blip) then RemoveBlip(item.blip) end
    if DoesEntityExist(item.entity) then DeleteObject(item.entity) end
    table.remove(Punish.comserv.trash, index)
end

local function clearTrash()
    for i = #Punish.comserv.trash, 1, -1 do
        removeTrash(i)
    end
end

local function spawnTrash()
    local model = GetHashKey(Config.ComServTrashProp)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    local base = Config.Locations.comservSpawn
    local spread = Config.ComServTrashSpread
    local x = base.x + math.random(-spread, spread)
    local y = base.y + math.random(-spread, spread)

    local obj = CreateObject(model, x, y, base.z, true, true, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    local blip = AddBlipForEntity(obj)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.8)

    table.insert(Punish.comserv.trash, { entity = obj, blip = blip })
    SetModelAsNoLongerNeeded(model)
end

local function syncTrash()
    local wanted = math.min(Punish.comserv.hours, Config.ComServTrashCount)
    while #Punish.comserv.trash < wanted do
        spawnTrash()
    end
    while #Punish.comserv.trash > wanted do
        removeTrash(#Punish.comserv.trash)
    end
end

local function pickupTrash(index)
    busy = true
    ExecuteCommand('e ' .. Config.Emotes.pickup)
    Wait(math.random(4000, 8000))
    ExecuteCommand('e ' .. Config.Emotes.reset)

    if DoesEntityExist(Punish.comserv.trash[index] and Punish.comserv.trash[index].entity or 0) then
        removeTrash(index)
        TriggerServerEvent('punish:comserv:task')
    end

    busy = false
end

RegisterNetEvent('punish:comserv:start', function(hours)
    Punish.comserv.active = true
    Punish.comserv.hours = hours
    Punish.comserv.total = hours
    Punish.applyClothes('comserv')

    for status, value in pairs(Config.ComServStatus) do
        TriggerEvent('esx_status:set', status, value)
    end

    syncTrash()
    Punish.sendHud()
end)

RegisterNetEvent('punish:comserv:hours', function(hours)
    if not Punish.comserv.active then return end
    Punish.comserv.hours = hours
    Punish.comserv.total = math.max(Punish.comserv.total, hours)
    syncTrash()
    Punish.sendHud()
end)

RegisterNetEvent('punish:comserv:end', function(reason)
    Punish.comserv.active = false
    Punish.comserv.hours = 0
    Punish.comserv.total = 0
    clearTrash()
    Punish.resetClothes()
    Punish.notify(Locale(reason == 'revoked' and 'notify.comserv_revoked_player' or 'notify.comserv_done'), 'success')
    Punish.sendHud()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if Punish.comserv.active and #Punish.comserv.trash > 0 and not busy then
            local coords = GetEntityCoords(PlayerPedId())
            local nearest, nearestDist = nil, Config.ComServPickupDistance

            for i, item in ipairs(Punish.comserv.trash) do
                if DoesEntityExist(item.entity) then
                    local dist = #(coords - GetEntityCoords(item.entity))
                    if dist < nearestDist then
                        nearest, nearestDist = i, dist
                    end
                end
            end

            if nearest then
                sleep = 0
                ESX.ShowHelpNotification(Locale('comserv.pickup_help'))
                if IsControlJustReleased(0, 38) then
                    local index = nearest
                    CreateThread(function()
                        pickupTrash(index)
                    end)
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if Punish.comserv.active then
            local spawn = Config.Locations.comservSpawn
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(spawn.x, spawn.y, spawn.z))
            if dist > Config.ComServMaxDistance then
                Punish.teleport(spawn)
                TriggerServerEvent('punish:comserv:penalty')
            end
        end
    end
end)
