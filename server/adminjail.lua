local adminSources = {}
local lastTick = {}

function Punish.adminjail.record(license)
    return MySQL.single.await('SELECT time, reason FROM admin_jail WHERE license = ?', { license })
end

function Punish.adminjail.apply(license, playerName, minutes, reason, adminName)
    MySQL.insert.await([[
        INSERT INTO admin_jail (license, player_name, time, reason, admin_name, dateandtime)
        VALUES (?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE player_name = VALUES(player_name), time = VALUES(time), reason = VALUES(reason), admin_name = VALUES(admin_name), dateandtime = NOW()
    ]], { license, playerName, minutes, reason, adminName })
end

function Punish.adminjail.start(src, license, minutes)
    adminSources[src] = license
    lastTick[src] = nil
    TriggerClientEvent('punish:adminjail:start', src, minutes)
end

function Punish.adminjail.release(license)
    MySQL.update.await('DELETE FROM admin_jail WHERE license = ?', { license })
    for src, lic in pairs(adminSources) do
        if lic == license then
            adminSources[src] = nil
            TriggerClientEvent('punish:adminjail:release', src, 'revoked')
        end
    end
end

function Punish.adminjail.restore(src, license)
    local record = Punish.adminjail.record(license)
    if record and record.time > 0 then
        Punish.adminjail.start(src, license, record.time)
    end
end

function Punish.adminjail.drop(src)
    adminSources[src] = nil
    lastTick[src] = nil
end

function Punish.adminjail.list()
    local rows = MySQL.query.await([[
        SELECT player_name AS name, time AS amount, reason, admin_name AS judge, UNIX_TIMESTAMP(dateandtime) AS ts
        FROM admin_jail
        ORDER BY dateandtime DESC
    ]], {})
    for _, row in ipairs(rows) do
        row.date = Punish.formatDate(row.ts)
        row.ts = nil
    end
    return rows
end

RegisterNetEvent('punish:adminjail:tick', function(active)
    local src = source
    local license = adminSources[src]
    if not license or type(active) ~= 'boolean' then return end

    local now = GetGameTimer()
    if lastTick[src] and now - lastTick[src] < (Config.AdminJailTickSeconds - 10) * 1000 then
        return
    end
    lastTick[src] = now
    if not active then return end

    local record = Punish.adminjail.record(license)
    if not record then
        adminSources[src] = nil
        TriggerClientEvent('punish:adminjail:release', src, 'revoked')
        return
    end

    local remaining = record.time - 1
    if remaining <= 0 then
        MySQL.update.await('DELETE FROM admin_jail WHERE license = ?', { license })
        adminSources[src] = nil
        TriggerClientEvent('punish:adminjail:release', src, 'expired')
    else
        MySQL.update.await('UPDATE admin_jail SET time = ? WHERE license = ?', { remaining, license })
        TriggerClientEvent('punish:adminjail:update', src, remaining)
    end
end)
