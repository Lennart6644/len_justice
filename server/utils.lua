ESX = exports['es_extended']:getSharedObject()

Punish = {
    jail = {},
    comserv = {},
    adminjail = {},
    pending = {},
}

local adminGroups = {}
for _, group in ipairs(Config.AdminGroups) do
    adminGroups[group] = true
end

local typeColors = {
    success = '~g~',
    error = '~r~',
    warning = '~y~',
    inform = '~b~',
}

function Punish.notify(src, description, ntype)
    if src == 0 then
        print(('[punish] %s'):format(description))
        return
    end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.showNotification((typeColors[ntype or 'inform'] or '') .. description)
    end
end

function Punish.trim(value)
    return (tostring(value or '')):match('^%s*(.-)%s*$')
end

function Punish.isAdmin(xPlayer)
    return xPlayer ~= nil and adminGroups[xPlayer.getGroup()] == true
end

function Punish.getRankEntry(xPlayer, jobs)
    if not xPlayer then return nil end
    local job = xPlayer.getJob()
    local entry = jobs[job.name]
    if entry and job.grade >= entry.minRank then
        return entry
    end
    return nil
end

function Punish.getPermissions(xPlayer)
    local judge = Punish.getRankEntry(xPlayer, Config.JudgeJobs)
    local jail = Punish.getRankEntry(xPlayer, Config.JailJobs)
    local comserv = Punish.getRankEntry(xPlayer, Config.ComServJobs)

    local perms = {
        canJudge = judge ~= nil,
        canJail = jail ~= nil,
        canRelease = Punish.getRankEntry(xPlayer, Config.ReleaseJobs) ~= nil,
        canComServ = comserv ~= nil,
        canUnComServ = Punish.getRankEntry(xPlayer, Config.UncomServJobs) ~= nil,
        isAdmin = Punish.isAdmin(xPlayer),
    }

    local limits = {
        jail = judge and judge.maxUnits or 0,
        comserv = comserv and comserv.maxComServ or 0,
    }

    return perms, limits
end

function Punish.license(src)
    local identifier = GetPlayerIdentifierByType(src, 'license')
    if not identifier then return nil end
    return identifier:match('license:(.+)') or identifier
end

function Punish.parseName(input)
    if type(input) ~= 'string' then return nil end
    local first, last = input:match('^%s*(%S+)%s+(.-)%s*$')
    if not first or not last or last == '' then return nil end
    return first, last
end

function Punish.resolveName(input)
    local first, last = Punish.parseName(input)
    if not first then return nil, 'invalid_name' end
    local rows = MySQL.query.await('SELECT identifier FROM users WHERE firstname = ? AND lastname = ? LIMIT 2', { first, last })
    if #rows == 0 then return nil, 'not_found' end
    if #rows > 1 then return nil, 'ambiguous' end
    return rows[1].identifier, nil
end

function Punish.validReason(value)
    if type(value) ~= 'string' then return nil end
    local trimmed = Punish.trim(value)
    if trimmed == '' or #trimmed > Config.MaxReasonLength then return nil end
    return trimmed
end

function Punish.validNumber(value, min, max)
    local number = tonumber(value)
    if not number or number ~= math.floor(number) or number < min or number > max then
        return nil
    end
    return math.floor(number)
end

function Punish.isNear(src, coords, radius)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= radius
end

function Punish.formatDate(timestamp)
    if not timestamp then return '-' end
    return os.date(Locale('format.datetime'), timestamp)
end
