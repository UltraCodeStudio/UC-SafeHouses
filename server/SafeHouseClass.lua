---@class SafeHouse : OxClass
---@field owner number
---@field upgrades table<string, table> -- Upgrade name | Upgrade data
---@field tier integer
---@field id string
---@field objects table<string, any>
---@field ipl table<vector4, string, number> -- Coords | name | Bucket
local SafeHouse = lib.class('SafeHouse')

---Constructor for SafeHouse
---@param owner number
---@param upgrades? table<string, table>
---@param tier? integer
---@param id? string
---@param objects? table<string, any>
function SafeHouse:constructor(owner, upgrades, tier, id, iplExitCoords, iplEnterCoords,  objects)
    self.owner = owner
    self.id = id or ('safehouse_%s'):format(owner)
    self.upgrades = upgrades or {}
    self.tier = tier or 1
    self.iplExitCoords = iplExitCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.iplEnterCoords = iplEnterCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.objects = objects or {}
    self:createTargets()
    if Config.Debug then
        print(('^1[DEBUG] ^7SafeHouse %s created with owner %d'):format(self.id, self.owner))
    end
end

---Check if a specific upgrade is installed
---@param name string
---@return boolean
function SafeHouse:hasUpgrade(name)
    if Config.Debug then
        print(('^1[DEBUG] ^7Checking if safehouse %s has upgrade %s'):format(self.id, name))
    end
    return self.upgrades[name] ~= nil
end

---Add or update an upgrade
---@param name string
---@param upgrade table
function SafeHouse:addUpgrade(name, upgrade)
    if Config.Debug then
        print(('^1[DEBUG] ^7Adding upgrade %s to safehouse %s'):format(name, self.id))
    end
    self.upgrades[name] = upgrade
end

---Remove an upgrade by name
---@param name string
function SafeHouse:removeUpgrade(name)
    if Config.Debug then
        print(('^1[DEBUG] ^7Removing upgrade %s from safehouse %s'):format(name, self.id))
    end
    self.upgrades[name] = nil
end

---Increase the safehouse tier
function SafeHouse:upgradeTier()
    self.tier = self.tier + 1
end

local function vec4ToTable(v)
    return { x = v.x, y = v.y, z = v.z, w = v.w }
end
---Serialize the SafeHouse to a storable table
---@return table<string, any>
function SafeHouse:serialize()
    return {
        owner = self.owner,
        tier = self.tier,
        id = self.id,
        upgrades = json.encode(self.upgrades or {}),
        objects = json.encode(self.objects or {}),
        iplExitCoords = json.encode(vec4ToTable(self.iplExitCoords)),
        iplEnterCoords = json.encode(vec4ToTable(self.iplEnterCoords)),
    }
end

function SafeHouse:save()
    if Config.Debug then
        print(('^1[DEBUG] ^7Saving safehouse %s to database'):format(self.id))
    end

    local data = self:serialize()

    local query = [[
        INSERT INTO uc_safehouses
            (id, owner, tier, enter_coords, exit_coords, upgrades, objects)
        VALUES
            (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            owner = VALUES(owner),
            tier = VALUES(tier),
            enter_coords = VALUES(enter_coords),
            exit_coords = VALUES(exit_coords),
            upgrades = VALUES(upgrades),
            objects = VALUES(objects)
    ]]

    local res = MySQL.query.await(query, {
        data.id, data.owner, data.tier,
        data.iplEnterCoords,
        data.iplExitCoords,
        data.upgrades, data.objects,
    })

    return res
end

function SafeHouse:createTargets()
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating targets for safehouse %s'):format(self.id))
    end
    
    TriggerClientEvent('uc-safehouses:client:createTargets', self.owner, self)
end

function SafeHouse:deleteTargets()
    if Config.Debug then
        print(('^1[DEBUG] ^7Deleting targets for safehouse %s'):format(self.id))
    end
end

function SafeHouse:isPlayerInSafeHouse(playerSrc)
    if not DoesPlayerExist(playerSrc) then
        print(('^1[ERROR] ^7Player %d does not exist checking safehouse %s'):format(playerSrc, self.id))
        return false
    end
    print(GetPlayerRoutingBucket(playerSrc), math.floor(self.iplEnterCoords.x))
    if GetPlayerRoutingBucket(playerSrc) == math.floor(self.iplEnterCoords.x) then
        if Config.Debug then
            print(('^1[DEBUG] ^7Player %d is in safehouse %s'):format(playerSrc, self.id))
        end
        return true
    end
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is NOT in safehouse %s'):format(playerSrc, self.id))
    end
    return false
end

function SafeHouse:playerEnter(enteredPlayerSrc)
    if not DoesPlayerExist(enteredPlayerSrc) then 
        print(('^1[ERROR] ^7Player %d does not exist trying to enter safehouse %s'):format(enteredPlayerSrc, self.id))
        return
    end
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is entering safehouse %s'):format(enteredPlayerSrc, self.id))
    end
    Wait(500)
    SetPlayerRoutingBucket(enteredPlayerSrc, self.iplEnterCoords.x)
    
    print(('^1[DEBUG] ^7Player %d routing bucket set to %d'):format(enteredPlayerSrc, GetPlayerRoutingBucket(enteredPlayerSrc)))
    SetEntityCoords(GetPlayerPed(enteredPlayerSrc), self.iplExitCoords.x, self.iplExitCoords.y, self.iplExitCoords.z, false, false, false, true)
end

function SafeHouse:playerExit(exitingPlayerSrc)
    if not DoesPlayerExist(exitingPlayerSrc) then 
        print(('^1[ERROR] ^7Player %d does not exist trying to exit safehouse %s'):format(exitingPlayerSrc, self.id))
    end
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is exiting safehouse %s'):format(exitingPlayerSrc, self.id))
    end
    Wait(500)
    SetPlayerRoutingBucket(exitingPlayerSrc, 0)
    SetEntityCoords(GetPlayerPed(exitingPlayerSrc), self.iplEnterCoords.x, self.iplEnterCoords.y, self.iplEnterCoords.z, false, false, false, true)
end

return SafeHouse
