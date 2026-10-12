Config = {}

Config.Language = 'en'

Config.AdminGroups = { 'admin', 'superadmin', 'projektleitung' }
Config.AdminJailAfkSeconds = 600
Config.AdminJailTickSeconds = 60
Config.AdminJailMaxMinutes = 10080
Config.JailUnitSeconds = 30
Config.MaxReasonLength = 55
Config.ComServPenaltyHours = 10
Config.ComServMaxDistance = 50.0
Config.ComServTrashCount = 8
Config.ComServTrashSpread = 20
Config.ComServTrashProp = 'proc_litter_01'
Config.ComServPickupDistance = 2.0
Config.ComServJudgeRadius = 100.0
Config.JailExecRadius = 100.0
Config.MarkerDistance = 3.0
Config.PromptDistance = 1.0

Config.Emotes = {
    mugshot = 'mugshot',
    pickup = 'mechanic3',
    reset = 'c',
}

Config.ComServStatus = {
    hunger = 750000,
    thirst = 750000,
}

Config.Locations = {
    mugshot = vector4(402.92, -996.73, -100.0, 180.0),
    mugshotCam = vector3(402.92, -998.0, -99.0),
    jailEnter = vector4(1700.2479, 2462.8042, 50.4525, 176.607),
    jailRelease = vector4(1839.0175, 2585.5688, 46.0143, 265.1022),
    jailExec = vector3(1788.1024, 2561.5613, 52.0565),
    jailDetails = vector4(1828.7938, 2580.2109, 46.0143, 174.4001),
    comservJudge = vector3(213.7388, -912.6823, 30.6921),
    comservSpawn = vector4(220.0159, -904.1716, 30.6908, 159.7087),
}

local jailClothes = {
    tshirt_1 = 15, tshirt_2 = 0,
    torso_1 = 146, torso_2 = 0,
    arms = 0,
    pants_1 = 3, pants_2 = 7,
    shoes_1 = 12, shoes_2 = 12,
}

local adminJailClothes = {
    tshirt_1 = 15, tshirt_2 = 0,
    torso_1 = 146, torso_2 = 0,
    arms = 0,
    pants_1 = 3, pants_2 = 5,
    shoes_1 = 12, shoes_2 = 12,
}

Config.Clothes = {
    jail = { male = jailClothes, female = jailClothes },
    adminJail = { male = adminJailClothes, female = adminJailClothes },
    comserv = {
        male = {
            tshirt_1 = 15, tshirt_2 = 0,
            torso_1 = 248, torso_2 = 14,
            arms = 16,
            pants_1 = 9, pants_2 = 1,
            shoes_1 = 51, shoes_2 = 3,
        },
        female = jailClothes,
    },
}

Config.JailJobs = {
    ['police'] = { minRank = 1, maxUnits = 60 },
    ['government'] = { minRank = 1, maxUnits = 300 },
    ['admin'] = { minRank = 0, maxUnits = 1000 },
}

Config.JudgeJobs = {
    ['police'] = { minRank = 1, maxUnits = 50 },
    ['government'] = { minRank = 1, maxUnits = 200 },
    ['admin'] = { minRank = 0, maxUnits = 1000 },
}

Config.ComServJobs = {
    ['police'] = { minRank = 1, maxComServ = 75 },
    ['government'] = { minRank = 1, maxComServ = 300 },
    ['admin'] = { minRank = 0, maxComServ = 5000 },
}

Config.ReleaseJobs = {
    ['government'] = { minRank = 1 },
    ['admin'] = { minRank = 0 },
}

Config.UncomServJobs = {
    ['government'] = { minRank = 1 },
    ['admin'] = { minRank = 0 },
    ['police'] = { minRank = 3 },
}
