---@class SafeHouse : OxClass
---@field owner string
---@field upgrades table<string, table> -- Upgrade name | Upgrade data
---@field tier integer
---@field id string
---@field objects table<string, any>
---@field ipl table<vector4, string, number> -- Coords | name | Bucket
---@field iplExitCoords vector4
---@field iplEnterCoords vector4
---@field controlLaptop vector4
---@field createTargets fun(self: SafeHouse)
---@field deleteTargets fun(self: SafeHouse)
---@field hasUpgrade fun(self: SafeHouse, name: string): boolean
---@field addUpgrade fun(self: SafeHouse, name: string, upgrade: table)
---@field removeUpgrade fun(self: SafeHouse, name: string)
---@field upgradeTier fun(self: SafeHouse)
---@field serialize fun(self: SafeHouse): table
---@field save fun(self: SafeHouse)
---@field isPlayerInSafeHouse fun(self: SafeHouse, playerSrc: number): boolean
---@field playerEnter fun(self: SafeHouse, playerSrc: number)
---@field playerExit fun(self: SafeHouse, playerSrc: number)
local SafeHouse = lib.class('SafeHouse')

---Constructor for SafeHouse
---@param owner string
---@param upgrades? table<string, table>
---@param tier? integer
---@param id? string
---@param iplExitCoords? vector4
---@param iplEnterCoords? vector4
---@param objects? table<string, any>
---@param controlLaptopCoords? vector4
function SafeHouse:constructor(owner, upgrades, tier, id, iplExitCoords, iplEnterCoords,  objects, controlLaptopCoords, safeCoords)
    Wait(100) 
    self.owner = owner
    self.id = id or ('safehouse_%s'):format(owner)
    self.upgrades = upgrades or {}
    self.tier = tier or 1
    self.iplExitCoords = iplExitCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.iplEnterCoords = iplEnterCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.objects = objects or {}
    self.controlLaptopCoords = controlLaptopCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.safeCoords = safeCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self:createTargets()
    self:createControlTable()
    self:createSafe()
    if Config.Debug then
        print(('^1[DEBUG] ^7SafeHouse %s created with owner %s'):format(self.id, self.owner))
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
    self:save()
end

---Remove an upgrade by name
---@param name string
function SafeHouse:removeUpgrade(name)
    if Config.Debug then
        print(('^1[DEBUG] ^7Removing upgrade %s from safehouse %s'):format(name, self.id))
    end
    self.upgrades[name] = nil
    self:save()
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
    if Config.Debug then
        print(('^1[DEBUG] ^7Safehouse %s saved to database with result: %s'):format(self.id, json.encode(res)))
    end
    return res
end


---@param model string
---@param coords vector4
---@param payload? table<string, any>
---@return integer
function SafeHouse:createObject(model, coords, payload)
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false, false)
    SetEntityRoutingBucket(obj, math.floor(self.iplEnterCoords.x))
    payload = payload or {}
    payload.model = model
    payload.coords = { x = coords.x, y = coords.y, z = coords.z }
    payload.id = self.id
    Entity(obj).state:set('uc_safehousesSpawnedObj', payload, true)
    self.objects[obj] = coords
    
    self:save()
    return obj
end

function SafeHouse:deleteObjects()
    
    for obj, coords in pairs(self.objects) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    self.objects = {}
end

function SafeHouse:createControlTable()
    return self:createObject(
        Config.ControlLaptop.model,
        self.controlLaptopCoords,
        {
            type = "controlLaptop",
            heading = self.controlLaptopCoords.w
        }
    )
end

function SafeHouse:createSafe()
    local safeModel = Config.Upgrades.vault[self.tier].model
    exports.ox_inventory:RegisterStash(self.id .. "_safe", self.id .. "_safe", Config.Upgrades.vault[self.tier].inventorySlots, Config.Upgrades.vault[self.tier].inventoryWeight)
    return self:createObject(
        safeModel,
        self.safeCoords,
        {
            type = "safe",
            heading = self.safeCoords.w
        }
    )
end

function SafeHouse:createTargets()
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating targets for safehouse %s'):format(self.id))
    end
    TriggerClientEvent('uc-safehouses:client:createTargets', -1, self)
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

    SetPlayerRoutingBucket(exitingPlayerSrc, 0)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d routing bucket reset to %d'):format(exitingPlayerSrc, GetPlayerRoutingBucket(exitingPlayerSrc)))
    end
    SetEntityCoords(GetPlayerPed(exitingPlayerSrc), self.iplEnterCoords.x, self.iplEnterCoords.y, self.iplEnterCoords.z, false, false, false, true)
end

return SafeHouse
