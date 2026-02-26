
local SafeHouse = require 'server.SafeHouseClass'

local safeHouses = {}


local player = exports.qbx_core:GetPlayer(2)
local playerData = player.PlayerData
local citizenid = playerData.citizenid
local sh = SafeHouse:new(citizenid, nil, 1, 'test_safehouse', vector4(134.89, -2203.47, 7.31, 86), vector4(132.39, -2205.39, 7.19, 178),nil,vector4(142.30, -2204.86, 4.69, 177),vector4(147.09, -2201.92, 4.69, 276))

sh:removeUpgrade("test")
sh:addUpgrade('vault', { level = 1, unlocked = true })
if sh:hasUpgrade('vault') then
    --print(sh.id, sh.owner, sh.tier, 'Vault upgrade installed!')
end

safeHouses[sh.id] = sh




sh:isPlayerInSafeHouse(1)
AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
        
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
