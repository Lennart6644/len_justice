local lastAction = {}

function Punish.comserv.getHours(identifier)
    local row = MySQL.single.await('SELECT social_hours_amount AS hours FROM social_hours WHERE identifier = ?', { identifier })
    return row and row.hours or 0
end

function Punish.comserv.assign(identifier, hours, reason, judgeName)
    MySQL.insert.await([[
        INSERT INTO social_hours (identifier, social_hours_amount, reason, judge, dateandtime)
        VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE social_hours_amount = VALUES(social_hours_amount), reason = VALUES(reason), judge = VALUES(judge), dateandtime = NOW()
    ]], { identifier, hours, reason, judgeName })
end

function Punish.comserv.setHours(identifier, hours)
    if hours <= 0 then
        MySQL.update.await('DELETE FROM social_hours WHERE identifier = ?', { identifier })
        return
    end
    MySQL.update.await('UPDATE social_hours SET social_hours_amount = ? WHERE identifier = ?', { hours, identifier })
end

function Punish.comserv.start(src, hours)
    TriggerClientEvent('punish:comserv:start', src, hours)
end

function Punish.comserv.release(identifier)
    MySQL.update.await('DELETE FROM social_hours WHERE identifier = ?', { identifier })
    local target = ESX.GetPlayerFromIdentifier(identifier)
    if target then
        TriggerClientEvent('punish:comserv:end', target.source, 'revoked')
    end
end

function Punish.comserv.restore(src, identifier)
    local hours = Punish.comserv.getHours(identifier)
    if hours > 0 then
        Punish.comserv.start(src, hours)
    end
end

function Punish.comserv.drop(src)
    lastAction[src] = nil
end

function Punish.comserv.list()
    local rows = MySQL.query.await([[
        SELECT CONCAT(u.firstname, ' ', u.lastname) AS name, s.social_hours_amount AS amount, s.reason, s.judge, UNIX_TIMESTAMP(s.dateandtime) AS ts
        FROM social_hours s
        LEFT JOIN users u ON u.identifier = s.identifier
        WHERE s.social_hours_amount > 0
        ORDER BY s.dateandtime DESC
    ]], {})
    for _, row in ipairs(rows) do
        row.date = Punish.formatDate(row.ts)
        row.ts = nil
    end
    return rows
end

local function cooldownPassed(src, ms)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < ms then
        return false
    end
    lastAction[src] = now
    return true
end

RegisterNetEvent('punish:comserv:task', function()
    local src = source
    if not cooldownPassed(src, 1000) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local hours = Punish.comserv.getHours(identifier)
    if hours <= 0 then return end

    local remaining = hours - 1
    Punish.comserv.setHours(identifier, remaining)

    if remaining <= 0 then
        TriggerClientEvent('punish:comserv:end', src, 'done')
    else
        TriggerClientEvent('punish:comserv:hours', src, remaining)
    end
end)

RegisterNetEvent('punish:comserv:penalty', function()
    local src = source
    if not cooldownPassed(src, 3000) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local hours = Punish.comserv.getHours(identifier)
    if hours <= 0 then return end

    local newHours = hours + Config.ComServPenaltyHours
    Punish.comserv.setHours(identifier, newHours)
    TriggerClientEvent('punish:comserv:hours', src, newHours)
    Punish.notify(src, Locale('notify.comserv_penalty', Config.ComServPenaltyHours), 'warning')
end)
