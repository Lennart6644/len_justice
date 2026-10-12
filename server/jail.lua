local jailedSources = {}
local pendingJails = {}
local nextPendingId = 1

function Punish.pending.add(entry)
    entry.id = nextPendingId
    nextPendingId = nextPendingId + 1
    pendingJails[entry.id] = entry
    return entry.id
end

function Punish.pending.get(id)
    return id and pendingJails[id] or nil
end

function Punish.pending.remove(id)
    pendingJails[id] = nil
end

function Punish.pending.hasIdentifier(identifier)
    for _, entry in pairs(pendingJails) do
        if entry.identifier == identifier then return true end
    end
    return false
end

function Punish.pending.list()
    local rows = {}
    for _, entry in pairs(pendingJails) do
        rows[#rows + 1] = {
            id = entry.id,
            name = entry.name,
            amount = entry.units,
            reason = entry.reason,
            judge = entry.judge,
        }
    end
    table.sort(rows, function(a, b) return a.id < b.id end)
    return rows
end

function Punish.jail.isJailed(identifier)
    local row = MySQL.single.await('SELECT jailtime FROM jail WHERE identifier = ?', { identifier })
    return row ~= nil and row.jailtime > 0
end

function Punish.jail.sentence(identifier, units, reason, judgeName)
    MySQL.insert.await([[
        INSERT INTO jail (identifier, jailtime, reason, judge, dateandtime)
        VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE jailtime = VALUES(jailtime), reason = VALUES(reason), judge = VALUES(judge), dateandtime = NOW()
    ]], { identifier, units, reason, judgeName })
end

function Punish.jail.start(src, identifier, units, mugshot)
    jailedSources[src] = identifier
    TriggerClientEvent('punish:jail:start', src, units, mugshot)
end

function Punish.jail.release(identifier)
    MySQL.update.await('DELETE FROM jail WHERE identifier = ?', { identifier })
    local target = ESX.GetPlayerFromIdentifier(identifier)
    if target then
        jailedSources[target.source] = nil
        TriggerClientEvent('punish:jail:release', target.source)
    end
end

function Punish.jail.restore(src, identifier)
    local row = MySQL.single.await('SELECT jailtime FROM jail WHERE identifier = ?', { identifier })
    if row and row.jailtime > 0 then
        Punish.jail.start(src, identifier, row.jailtime, false)
    end
end

function Punish.jail.drop(src)
    jailedSources[src] = nil
end

function Punish.jail.own(identifier)
    local row = MySQL.single.await([[
        SELECT jailtime AS units, reason, judge, UNIX_TIMESTAMP(dateandtime) AS ts
        FROM jail WHERE identifier = ? AND jailtime > 0
    ]], { identifier })
    if row then
        row.date = Punish.formatDate(row.ts)
        row.ts = nil
    end
    return row
end

function Punish.jail.list()
    local rows = MySQL.query.await([[
        SELECT CONCAT(u.firstname, ' ', u.lastname) AS name, j.jailtime AS amount, j.reason, j.judge, UNIX_TIMESTAMP(j.dateandtime) AS ts
        FROM jail j
        LEFT JOIN users u ON u.identifier = j.identifier
        WHERE j.jailtime > 0
        ORDER BY j.dateandtime DESC
    ]], {})
    for _, row in ipairs(rows) do
        row.date = Punish.formatDate(row.ts)
        row.ts = nil
    end
    return rows
end

CreateThread(function()
    while true do
        Wait(Config.JailUnitSeconds * 1000)
        local snapshot = {}
        for src, identifier in pairs(jailedSources) do
            snapshot[#snapshot + 1] = { src = src, identifier = identifier }
        end
        for _, entry in ipairs(snapshot) do
            local row = MySQL.single.await('SELECT jailtime FROM jail WHERE identifier = ?', { entry.identifier })
            if not row or not ESX.GetPlayerFromId(entry.src) then
                jailedSources[entry.src] = nil
            else
                local remaining = row.jailtime - 1
                if remaining <= 0 then
                    MySQL.update.await('DELETE FROM jail WHERE identifier = ?', { entry.identifier })
                    jailedSources[entry.src] = nil
                    TriggerClientEvent('punish:jail:release', entry.src)
                else
                    MySQL.update.await('UPDATE jail SET jailtime = ? WHERE identifier = ?', { remaining, entry.identifier })
                    TriggerClientEvent('punish:jail:update', entry.src, remaining)
                end
            end
        end
    end
end)
