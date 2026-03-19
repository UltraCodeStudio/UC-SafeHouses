
local SafeHouse = require 'server.SafeHouseClass'

local safeHouses = {}

if false then
    local player = exports.qbx_core:GetPlayer(1)
    local playerData = player.PlayerData
    local citizenid = playerData.citizenid
    local sh = SafeHouse:new({
        owner = citizenid,
        tier = 1,
        id = 'test_safehouse',

        iplExitCoords  = vector4(-75.86, -826.98, 243.38, 31.0),
        iplEnterCoords = vector4(-71.27, -800.93,  44.23, 183.0),

        controlLaptopCoords = vector4(-75.24, -816.00, 243.39, 240),
        safeCoords          = vector4(-71.06, -817.70, 243.39, 121),

        upgrades = {},      -- optional
        objects = {},       -- optional
    })
    safeHouses[sh.id] = sh
end
-- sh:removeUpgrade("test")
-- sh:addUpgrade('vault', { level = 1, unlocked = true })
-- if sh:hasUpgrade('vault') then
--     --print(sh.id, sh.owner, sh.tier, 'Vault upgrade installed!')
-- end

RegisterNetEvent('uc-safehouses:server:createSafeHouse', function(data)
    local src = source
    local sh = SafeHouse:new(data)
    safeHouses[sh.id] = sh
    if Config.Debug then
        print(('^1[DEBUG] ^7Created safehouse %s for owner %s with tier %s'):format(
            tostring(sh.id), tostring(sh.owner), tostring(sh.tier)
        ))
    end
end)

function LoadSafeHouses()
    local query = [[SELECT * FROM uc_safehouses]]
    local rows = MySQL.query.await(query) or {}
    if Config.Debug then
        print(('^1[DEBUG] ^7Loaded %d safehouses'):format(#rows))
    end
    for _, data in ipairs(rows) do
        local sh = SafeHouse:new({
            owner = data.owner,
            upgrades = json.decode(data.upgrades),
            tier = data.tier,
            id = data.id,
            iplExitCoords = json.decode(data.exit_coords),
            iplEnterCoords = json.decode(data.enter_coords),
            objects = json.decode(data.objects),
            controlLaptopCoords = json.decode(data.laptop_coords),
            safeCoords = json.decode(data.safe_coords)
        })
        safeHouses[sh.id] = sh
        if Config.Debug then
            print(('^1[DEBUG]^7 Loaded safehouse %s for owner %s with tier %s'):format(
                tostring(sh.id), tostring(sh.owner), tostring(sh.tier)
            ))
        end
    end
end

function KickPlayersOutSafeHouses()
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        for _, safeHouse in pairs(safeHouses) do
            if safeHouse:isPlayerInSafeHouse(src) then
                    safeHouse:playerExit(src)
                break
            end
        end
    end
end

AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
        Wait(1000) -- Wait for the database to be ready 
        LoadSafeHouses()
        if Config.KickPlayersOutOnResourceStop then
            KickPlayersOutSafeHouses()
        end
        
   end
end)

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
        for _, sh in pairs(safeHouses) do
            sh:deleteTargets()
            sh:deleteObjects()
        end
        
   end
end)

RegisterNetEvent('uc-safehouses:server:enterSafeHouse')
AddEventHandler('uc-safehouses:server:enterSafeHouse', function(shId)
    local src = source
    local sh = safeHouses[shId]
    if sh then
        sh:playerEnter(src)
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)

RegisterNetEvent('uc-safeHouses:server:moveControlTable')
AddEventHandler('uc-safeHouses:server:moveControlTable', function(shId, coords)
    local src = source
    local sh = safeHouses[shId]
    if sh then
        sh:moveControlTable(coords)
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)

RegisterNetEvent('uc-safeHouses:server:moveSafe')
AddEventHandler('uc-safeHouses:server:moveSafe', function(shId, coords)
    local src = source
    local sh = safeHouses[shId]
    if sh then
        sh:moveSafe(coords)
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)

RegisterNetEvent('uc-safehouses:server:exitSafeHouse')
AddEventHandler('uc-safehouses:server:exitSafeHouse', function(shId)    
    local src = source
    local sh = safeHouses[shId]
    if sh then
        sh:playerExit(src)
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)

RegisterNetEvent('uc-safehouses:server:addUpgrade')
AddEventHandler('uc-safehouses:server:addUpgrade', function(shId, name, tier)    
    local src = source
    local sh = safeHouses[shId]
    if sh then
        sh:addUpgrade(name, { level = tier })
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)

lib.callback.register('uc-safehouses:server:isPlayerInSafeHouse', function(src, shId)
    local sh = safeHouses[shId]
    if sh then
        return sh:isPlayerInSafeHouse(src)
    else
        print(('^1[ERROR] ^7SafeHouse with ID %s not found for player %d'):format(shId, src))
    end
end)
