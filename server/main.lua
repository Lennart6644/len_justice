local actions = {}

actions.jail_create = function(src, xPlayer, data)
    local rule = Punish.getRankEntry(xPlayer, Config.JudgeJobs)
    if not rule then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end

    local units = Punish.validNumber(data.units, 1, rule.maxUnits)
    local reason = Punish.validReason(data.reason)
    if not units or not reason then
        return Punish.notify(src, Locale('notify.invalid_input'), 'error')
    end

    local identifier, err = Punish.resolveName(data.name)
    if not identifier then
        return Punish.notify(src, Locale('notify.resolve_' .. err), 'error')
    end
    if Punish.jail.isJailed(identifier) then
        return Punish.notify(src, Locale('notify.already_jailed'), 'error')
    end
    if Punish.pending.hasIdentifier(identifier) then
        return Punish.notify(src, Locale('notify.pending_exists'), 'error')
    end

    Punish.pending.add({
        identifier = identifier,
        name = Punish.trim(data.name),
        units = units,
        reason = reason,
        judge = xPlayer.getName(),
    })

    Punish.notify(src, Locale('notify.sentence_created'), 'success')
    local target = ESX.GetPlayerFromIdentifier(identifier)
    if target then
        Punish.notify(target.source, Locale('notify.sentenced', units, reason), 'warning')
    end
end

actions.jail_execute = function(src, xPlayer, data)
    local rule = Punish.getRankEntry(xPlayer, Config.JailJobs)
    if not rule then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end
    if not Punish.isNear(src, Config.Locations.jailExec, Config.JailExecRadius) then
        return Punish.notify(src, Locale('notify.too_far_jail'), 'error')
    end

    local entry = Punish.pending.get(tonumber(data.id))
    if not entry then
        return Punish.notify(src, Locale('notify.pending_missing'), 'error')
    end
    if entry.units > rule.maxUnits then
        return Punish.notify(src, Locale('notify.invalid_input'), 'error')
    end

    local target = ESX.GetPlayerFromIdentifier(entry.identifier)
    if not target then
        return Punish.notify(src, Locale('notify.not_online'), 'error')
    end
    if Punish.jail.isJailed(entry.identifier) then
        Punish.pending.remove(entry.id)
        return Punish.notify(src, Locale('notify.already_jailed'), 'error')
    end

    Punish.jail.sentence(entry.identifier, entry.units, entry.reason, entry.judge)
    Punish.pending.remove(entry.id)
    Punish.jail.start(target.source, entry.identifier, entry.units, true)
    Punish.notify(src, Locale('notify.jail_executed'), 'success')
end

actions.jail_release = function(src, xPlayer, data)
    if not Punish.getRankEntry(xPlayer, Config.ReleaseJobs) then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end

    local identifier, err = Punish.resolveName(data.name)
    if not identifier then
        return Punish.notify(src, Locale('notify.resolve_' .. err), 'error')
    end
    if not Punish.jail.isJailed(identifier) then
        return Punish.notify(src, Locale('notify.not_jailed'), 'error')
    end

    Punish.jail.release(identifier)
    Punish.notify(src, Locale('notify.jail_released'), 'success')
end

actions.comserv_assign = function(src, xPlayer, data)
    local rule = Punish.getRankEntry(xPlayer, Config.ComServJobs)
    if not rule then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end
    if not Punish.isNear(src, Config.Locations.comservJudge, Config.ComServJudgeRadius) then
        return Punish.notify(src, Locale('notify.too_far_comserv'), 'error')
    end

    local hours = Punish.validNumber(data.hours, 1, rule.maxComServ)
    local reason = Punish.validReason(data.reason)
    if not hours or not reason then
        return Punish.notify(src, Locale('notify.invalid_input'), 'error')
    end

    local identifier, err = Punish.resolveName(data.name)
    if not identifier then
        return Punish.notify(src, Locale('notify.resolve_' .. err), 'error')
    end
    if Punish.comserv.getHours(identifier) > 0 then
        return Punish.notify(src, Locale('notify.already_comserv'), 'error')
    end

    local target = ESX.GetPlayerFromIdentifier(identifier)
    if not target then
        return Punish.notify(src, Locale('notify.not_online'), 'error')
    end

    Punish.comserv.assign(identifier, hours, reason, xPlayer.getName())
    Punish.comserv.start(target.source, hours)
    Punish.notify(target.source, Locale('notify.comserv_assigned_player', hours, reason), 'warning')
    Punish.notify(src, Locale('notify.comserv_assigned'), 'success')
end

actions.comserv_revoke = function(src, xPlayer, data)
    if not Punish.getRankEntry(xPlayer, Config.UncomServJobs) then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end

    local identifier, err = Punish.resolveName(data.name)
    if not identifier then
        return Punish.notify(src, Locale('notify.resolve_' .. err), 'error')
    end
    if Punish.comserv.getHours(identifier) <= 0 then
        return Punish.notify(src, Locale('notify.not_comserv'), 'error')
    end

    Punish.comserv.release(identifier)
    Punish.notify(src, Locale('notify.comserv_revoked'), 'success')
end

actions.admin_punish = function(src, xPlayer, data)
    if not Punish.isAdmin(xPlayer) then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end

    local targetId = tonumber(data.id)
    local target = targetId and ESX.GetPlayerFromId(targetId)
    if not target then
        return Punish.notify(src, Locale('notify.not_online'), 'error')
    end

    local minutes = Punish.validNumber(data.minutes, 1, Config.AdminJailMaxMinutes)
    local reason = Punish.validReason(data.reason)
    if not minutes or not reason then
        return Punish.notify(src, Locale('notify.invalid_input'), 'error')
    end

    local license = Punish.license(target.source)
    if not license then
        return Punish.notify(src, Locale('notify.not_online'), 'error')
    end

    Punish.adminjail.apply(license, target.getName(), minutes, reason, xPlayer.getName())
    Punish.adminjail.start(target.source, license, minutes)
    Punish.notify(target.source, Locale('notify.admin_applied_player', minutes, reason), 'error')
    Punish.notify(src, Locale('notify.admin_applied'), 'success')
end

actions.admin_release = function(src, xPlayer, data)
    if not Punish.isAdmin(xPlayer) then
        return Punish.notify(src, Locale('notify.no_permission'), 'error')
    end

    local targetId = tonumber(data.id)
    local target = targetId and ESX.GetPlayerFromId(targetId)
    if not target then
        return Punish.notify(src, Locale('notify.not_online'), 'error')
    end

    local license = Punish.license(target.source)
    if not license or not Punish.adminjail.record(license) then
        return Punish.notify(src, Locale('notify.admin_not_active'), 'error')
    end

    Punish.adminjail.release(license)
    Punish.notify(src, Locale('notify.admin_released'), 'success')
end

RegisterNetEvent('punish:action', function(action, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local handler = actions[action]
    if not xPlayer or not handler or type(data) ~= 'table' then return end

    local ok, err = pcall(handler, src, xPlayer, data)
    if not ok then
        print(('^1[punish] action %s failed: %s^7'):format(tostring(action), tostring(err)))
    end
end)

ESX.RegisterServerCallback('punish:fetch', function(source, cb, kind)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    if kind == 'pending' then
        if not Punish.getRankEntry(xPlayer, Config.JailJobs) then return cb({}) end
        return cb(Punish.pending.list())
    elseif kind == 'jailed' then
        if not (Punish.getRankEntry(xPlayer, Config.JailJobs) or Punish.getRankEntry(xPlayer, Config.JudgeJobs)) then return cb({}) end
        return cb(Punish.jail.list())
    elseif kind == 'comserv' then
        if not (Punish.getRankEntry(xPlayer, Config.ComServJobs) or Punish.getRankEntry(xPlayer, Config.UncomServJobs)) then return cb({}) end
        return cb(Punish.comserv.list())
    elseif kind == 'adminjailed' then
        if not Punish.isAdmin(xPlayer) then return cb({}) end
        return cb(Punish.adminjail.list())
    end

    cb({})
end)

ESX.RegisterServerCallback('punish:ownJail', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    cb(Punish.jail.own(xPlayer.getIdentifier()))
end)

RegisterCommand('punish', function(source)
    if source == 0 then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local perms, limits = Punish.getPermissions(xPlayer)
    if not (perms.canJudge or perms.canJail or perms.canRelease or perms.canComServ or perms.canUnComServ) then
        return Punish.notify(source, Locale('notify.no_permission'), 'error')
    end
    TriggerClientEvent('punish:client:open', source, 'justice', perms, limits)
end, false)

RegisterCommand('adminjail', function(source)
    if source == 0 then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not Punish.isAdmin(xPlayer) then
        return Punish.notify(source, Locale('notify.admin_denied'), 'error')
    end
    TriggerClientEvent('punish:client:open', source, 'admin', { isAdmin = true }, { jail = 0, comserv = 0 })
end, false)

local function aceDenied(src, ace)
    return src ~= 0 and not IsPlayerAceAllowed(src, ace)
end

local function cmdNotify(src, key, ntype)
    if src == 0 then
        print(('[punish] %s'):format(Locale(key)))
    else
        Punish.notify(src, Locale(key), ntype or 'inform')
    end
end

local function judgeName(src)
    if src == 0 then return Locale('notify.console') end
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.getName() or Locale('notify.console')
end

RegisterCommand('quickpunish', function(src, args)
    if aceDenied(src, 'command.quickpunish') then
        return cmdNotify(src, 'notify.no_permission', 'error')
    end

    local targetId = tonumber(args[1])
    local kind = args[2]
    local amount = tonumber(args[3])
    local reason = Punish.validReason(table.concat(args, ' ', 4))
    if not targetId or not kind or not amount or not reason then
        return cmdNotify(src, 'notify.quick_usage', 'error')
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return cmdNotify(src, 'notify.not_online', 'error')
    end

    local identifier = target.getIdentifier()
    local judge = judgeName(src)

    if kind == 'jail' then
        local units = Punish.validNumber(amount, 1, 1000)
        if not units then return cmdNotify(src, 'notify.invalid_input', 'error') end
        if Punish.jail.isJailed(identifier) then return cmdNotify(src, 'notify.quick_already', 'error') end
        Punish.jail.sentence(identifier, units, reason, judge)
        Punish.jail.start(target.source, identifier, units, true)
        cmdNotify(src, 'notify.quick_done', 'success')
    elseif kind == 'comserv' then
        local hours = Punish.validNumber(amount, 1, 5000)
        if not hours then return cmdNotify(src, 'notify.invalid_input', 'error') end
        if Punish.comserv.getHours(identifier) > 0 then return cmdNotify(src, 'notify.quick_already', 'error') end
        Punish.comserv.assign(identifier, hours, reason, judge)
        Punish.comserv.start(target.source, hours)
        cmdNotify(src, 'notify.quick_done', 'success')
    else
        cmdNotify(src, 'notify.quick_invalid_type', 'error')
    end
end, false)

RegisterCommand('quickrelease', function(src, args)
    if aceDenied(src, 'command.quickrelease') then
        return cmdNotify(src, 'notify.no_permission', 'error')
    end

    local targetId = tonumber(args[1])
    local kind = args[2]
    if not targetId or not kind then
        return cmdNotify(src, 'notify.quick_release_usage', 'error')
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return cmdNotify(src, 'notify.not_online', 'error')
    end

    local identifier = target.getIdentifier()

    if kind == 'jail' then
        if not Punish.jail.isJailed(identifier) then return cmdNotify(src, 'notify.not_jailed', 'error') end
        Punish.jail.release(identifier)
        cmdNotify(src, 'notify.quick_released', 'success')
    elseif kind == 'comserv' then
        if Punish.comserv.getHours(identifier) <= 0 then return cmdNotify(src, 'notify.not_comserv', 'error') end
        Punish.comserv.release(identifier)
        cmdNotify(src, 'notify.quick_released', 'success')
    else
        cmdNotify(src, 'notify.quick_invalid_type', 'error')
    end
end, false)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    CreateThread(function()
        Wait(2500)
        if not ESX.GetPlayerFromId(playerId) then return end
        local identifier = xPlayer.getIdentifier()
        local license = Punish.license(playerId)
        Punish.jail.restore(playerId, identifier)
        Punish.comserv.restore(playerId, identifier)
        if license then
            Punish.adminjail.restore(playerId, license)
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    Punish.jail.drop(src)
    Punish.comserv.drop(src)
    Punish.adminjail.drop(src)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(5000)
        for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
            local src = xPlayer.source
            local license = Punish.license(src)
            Punish.jail.restore(src, xPlayer.getIdentifier())
            Punish.comserv.restore(src, xPlayer.getIdentifier())
            if license then
                Punish.adminjail.restore(src, license)
            end
        end
    end)
end)
