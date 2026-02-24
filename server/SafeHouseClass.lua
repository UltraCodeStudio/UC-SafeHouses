---@class SafeHouse : OxClass
---@field owner number
---@field upgrades table<string, table> -- Upgrade name | Upgrade data
---@field tier integer
---@field id string
---@field data table<string, any>
---@field ipl table<vector4, string, number> -- Coords | name | Bucket
local SafeHouse = lib.class('SafeHouse')

---Constructor for SafeHouse
---@param owner number
---@param upgrades? table<string, table>
---@param tier? integer
---@param id? string
---@param data? table<string, any>
function SafeHouse:constructor(owner, upgrades, tier, id, iplExitCoords, iplEnterCoords,  data)
    self.owner = owner
    self.id = id or ('safehouse_%s'):format(owner)
    self.upgrades = upgrades or {}
    self.tier = tier or 1
    self.iplExitCoords = iplExitCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.iplEnterCoords = iplEnterCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.data = data or {}
    self.ipl = {}
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

---Serialize the SafeHouse to a storable table
---@return table<string, any>
function SafeHouse:serialize()
    return {
        owner = self.owner,
        tier = self.tier,
        id = self.id,
        upgrades = self.upgrades,
        data = self.data,
        iplExitCoords = self.iplExitCoords,
        iplEnterCoords = self.iplEnterCoords
    }
end

function SafeHouse:createTargets()
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating targets for safehouse %s'):format(self.id))
    end
end

function SafeHouse:playerEnter(enteredPlayerSrc)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is entering safehouse %s'):format(enteredPlayerSrc, self.id))
    end
    Wait(500)
    SetEntityRoutingBucket(GetPlayerPed(enteredPlayerSrc), self.iplExitCoords.w)
    SetEntityCoords(GetPlayerPed(enteredPlayerSrc), self.iplExitCoords.x, self.iplExitCoords.y, self.iplExitCoords.z, false, false, false, true)
end

function SafeHouse:playerExit(exitingPlayerSrc)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is exiting safehouse %s'):format(exitingPlayerSrc, self.id))
    end
    Wait(500)
    SetEntityRoutingBucket(GetPlayerPed(exitingPlayerSrc), 0)
    SetEntityCoords(GetPlayerPed(exitingPlayerSrc), self.iplEnterCoords.x, self.iplEnterCoords.y, self.iplEnterCoords.z, false, false, false, true)
end

return SafeHouse
