

local function createEntranceTarget(sh)
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating entrance target for safehouse %s'):format(sh.id))
    end
    local target = {
        name = sh.id .. "_entrance",
        label = "Enter Safehouse",
        coords = vec3(sh.iplEnterCoords.x, sh.iplEnterCoords.y, sh.iplEnterCoords.z),
        size = vec3(1.0, 1.0, 2.0),
        rotation = sh.iplEnterCoords.w,
        debug = Config.Debug,
        onSelect = function()
            TriggerServerEvent('uc-safehouses:server:enterSafeHouse', sh.id)
        end
    }
    CreateBoxTarget(target)
end

local function createExitTarget(sh)
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating exit target for safehouse %s'):format(sh.id))
    end
    local target = {
        name = sh.id .. "_exit",
        label = "Exit Safehouse",
        coords = vec3(sh.iplExitCoords.x, sh.iplExitCoords.y, sh.iplExitCoords.z),
        size = vec3(1.0, 1.0, 2.0),
        rotation = sh.iplExitCoords.w,
        debug = Config.Debug,
        onSelect = function()
            TriggerServerEvent('uc-safehouses:server:exitSafeHouse', sh.id)
        end
    }
    CreateBoxTarget(target)
end

local function createControlLaptopTarget(ent, sh)
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating control laptop target for safehouse %s'):format(sh.id))
    end
    local options = {
        name = sh.id .. "_control_laptop",
        label = "Control Laptop",
        debug = Config.Debug,
        onSelect = function()
            if Config.Debug then
                print(('^1[DEBUG] ^7Interacted with control laptop for safehouse %s'):format(sh.id))
            end
            ShowLaptopMenu(sh)
        end
    }
    AddLocalEntity(ent, options)
end

local function createSafeTarget(ent, sh)
    if Config.Debug then
        print(('^1[DEBUG] ^7Creating safe target for safehouse %s'):format(sh.id))
    end
    local options = {
        name = sh.id .. "_safe",

        label = "Safe",
        debug = Config.Debug,
        onSelect = function()
            if Config.Debug then
                print(('^1[DEBUG] ^7Interacted with safe for safehouse %s'):format(sh.id))
            end
            
            
            exports.ox_inventory:openInventory('stash', sh.id.."_safe")
            
        end
    }
    AddLocalEntity(ent, options)
end

local handlers = {
  controlLaptop = function(ent, sh)
    createControlLaptopTarget(ent, sh)
  end,
  safe = function (ent, sh)
    createSafeTarget(ent, sh)
  end,
}

AddStateBagChangeHandler('uc_safehousesSpawnedObj', nil, function(bagName, key, sh, _unused)
  if type(sh) ~= 'table' then return end

  local ent = GetEntityFromStateBagName(bagName)
  if ent == 0 or not DoesEntityExist(ent) then return end

    SetEntityHeading(ent, sh.heading or 0.0)
    FreezeEntityPosition(ent, true)
    PlaceObjectOnGroundProperly(ent)

  local fn = handlers[sh.type]
  if fn then
    fn(ent, sh)
  end
end)

RegisterNetEvent('uc-safehouses:client:createTargets')
AddEventHandler('uc-safehouses:client:createTargets', function(sh)
    print(('Creating targets for safehouse %s on client %s'):format(sh.id, source))
    createEntranceTarget(sh)
    createExitTarget(sh)
end)



