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
            -- Implement laptop interaction here
            print('Interacted with control laptop for safehouse ' .. sh.id)
        end
    }
    AddLocalEntity(ent, options)
end

AddStateBagChangeHandler('uc_safehousesSpawnedObj', nil, function(bagName, key, sh, _unused)
    if type(sh) ~= 'table' then return end

    local ent = GetEntityFromStateBagName(bagName)
    if ent == 0 or not DoesEntityExist(ent) then return end
    
    createControlLaptopTarget(ent, sh)
    SetEntityHeading(ent, sh.controlLaptopCoords.w)
    FreezeEntityPosition(ent, true)
    PlaceObjectOnGroundProperly(ent)

    
end)
RegisterNetEvent('uc-safehouses:client:createTargets')
AddEventHandler('uc-safehouses:client:createTargets', function(sh)
    print(('Creating targets for safehouse %s on client %s'):format(sh.id, source))
    createEntranceTarget(sh)
    createExitTarget(sh)
end)



