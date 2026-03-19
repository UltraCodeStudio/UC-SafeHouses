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

---@class SafeHouse
---@field owner string
---@field id string
---@field upgrades table
---@field tier integer
---@field iplExitCoords vector4
---@field iplEnterCoords vector4
---@field objects table
---@field controlLaptopCoords vector4
---@field safeCoords vector4

---@param data table
---@param data.owner string
---@param data.upgrades? table
---@param data.tier? integer
---@param data.id? string
---@param data.iplExitCoords? vector4
---@param data.iplEnterCoords? vector4
---@param data.objects? table
---@param data.controlLaptopCoords? vector4
---@param data.safeCoords? vector4
function SafeHouse:constructor(data)
    local owner = data.owner
    Wait(1000)
    assert(owner, 'SafeHouse owner is required')

    self.owner = owner
    self.id = data.id or ('safehouse_%s'):format(owner)
    self.upgrades = data.upgrades or {}
    self.tier = data.tier or 1
    self.iplExitCoords = data.iplExitCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.iplEnterCoords = data.iplEnterCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.objects = data.objects or {}
    self.controlLaptopCoords = data.controlLaptopCoords or vector4(0.0, 0.0, 0.0, 0.0)
    self.safeCoords = data.safeCoords or vector4(0.0, 0.0, 0.0, 0.0)

    self.routingBucketId = self:createRoutingBucketId()
    self:createTargets()
    self.controlLaptop = self:createControlTable()
    self.safe = self:createSafe()
    
    if Config.Debug then
        print(('^1[DEBUG] ^7SafeHouse %s created with owner %s'):format(self.id, self.owner))
    end
end

---@param str string
---@return number
local function nameToBucket(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + str:byte(i)) % 2147483647
    end
    return (hash % 999999) + 1
end

---@return number
function SafeHouse:createRoutingBucketId()
    return nameToBucket(self.id)
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


---Serialize the SafeHouse to a storable table
---@return table<string, any>
function SafeHouse:serialize()
    return {
        owner = self.owner,
        tier = self.tier,
        id = self.id,
        upgrades = json.encode(self.upgrades or {}),
        objects = json.encode(self.objects or {}),
        exit_coords = json.encode(self.iplExitCoords),
        enter_coords = json.encode(self.iplEnterCoords),
        laptop_coords = json.encode(self.controlLaptopCoords),
        safe_coords = json.encode(self.safeCoords),
    }
end



function SafeHouse:save()
    
    if Config.Debug then
        print(('^1[DEBUG] ^7Saving safehouse %s to database'):format(self.id))
    end

    local data = self:serialize()

    local query = [[
        INSERT INTO uc_safehouses
            (id, owner, tier, enter_coords, exit_coords, safe_coords, laptop_coords, upgrades, objects)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            owner = VALUES(owner),
            tier = VALUES(tier),
            enter_coords = VALUES(enter_coords),
            exit_coords = VALUES(exit_coords),
            safe_coords = VALUES(safe_coords),
            laptop_coords = VALUES(laptop_coords),
            upgrades = VALUES(upgrades),
            objects = VALUES(objects)
    ]]

    local res = MySQL.query.await(query, {
        data.id, data.owner, data.tier,
        data.enter_coords,
        data.exit_coords,
        data.safe_coords,
        data.laptop_coords,
        data.upgrades,
        data.objects,
        
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
function SafeHouse:createObject(model, coords, payload, save)
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false, false)
    SetEntityRoutingBucket(obj, self.routingBucketId)
    payload = payload or {}
    payload.model = model
    payload.coords = { x = coords.x, y = coords.y, z = coords.z }
    payload.id = self.id
    payload.sh = self
    Entity(obj).state:set('uc_safehousesSpawnedObj', payload, true)
    if save then
        self.objects[obj] = coords
    end
    self:save()
    return obj
end

function SafeHouse:moveControlTable(coords)
    self:deleteObject(self.controlLaptop)
    self.controlLaptopCoords = coords
    self.controlLaptop = self:createControlTable()
end

function SafeHouse:moveSafe(coords)
    self:deleteObject(self.safe)
    self.safeCoords = coords
    self.safe = self:createSafe()
end

function SafeHouse:deleteObjects()
    for obj, coords in pairs(self.objects) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    self.objects = {}
    self:deleteObject(self.controlLaptop)
    self:deleteObject(self.safe)
end

function SafeHouse:deleteObject(obj)
    if DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    self.objects[obj] = nil
end

function SafeHouse:createControlTable()
    return self:createObject(
        Config.ControlLaptop.model,
        self.controlLaptopCoords,
        {
            type = "controlLaptop",
            heading = self.controlLaptopCoords.w
        },
        false
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
        },
        false
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
    if GetPlayerRoutingBucket(playerSrc) == self.routingBucketId then
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
    local ped = GetPlayerPed(enteredPlayerSrc)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is entering safehouse %s'):format(enteredPlayerSrc, self.id))
    end
    SetPlayerRoutingBucket(enteredPlayerSrc, self.routingBucketId)
    if Config.Debug then    
        print(('^1[DEBUG] ^7Player %d routing bucket set to %d'):format(enteredPlayerSrc, self.routingBucketId))
    end
    SetEntityCoords(ped, self.iplExitCoords.x, self.iplExitCoords.y, self.iplExitCoords.z, false, false, false, false)
end

function SafeHouse:playerExit(exitingPlayerSrc)
    if not DoesPlayerExist(exitingPlayerSrc) then 
        print(('^1[ERROR] ^7Player %d does not exist trying to exit safehouse %s'):format(exitingPlayerSrc, self.id))
    end
    local ped = GetPlayerPed(exitingPlayerSrc)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d is exiting safehouse %s'):format(exitingPlayerSrc, self.id))
    end

    SetPlayerRoutingBucket(exitingPlayerSrc, 0)
    if Config.Debug then
        print(('^1[DEBUG] ^7Player %d routing bucket reset to %d'):format(exitingPlayerSrc, GetPlayerRoutingBucket(exitingPlayerSrc)))
    end
    SetEntityCoords(ped, self.iplEnterCoords.x, self.iplEnterCoords.y, self.iplEnterCoords.z, false, false, false, false)
end

return SafeHouse
