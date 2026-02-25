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
        debug = true,
        onSelect = function()
            TriggerServerEvent('uc-safehouses:server:exitSafeHouse', sh.id)
        end
    }
    CreateBoxTarget(target)
end

RegisterNetEvent('uc-safehouses:client:createTargets')
AddEventHandler('uc-safehouses:client:createTargets', function(sh)
    print(('Creating targets for safehouse %s on client %s'):format(sh.id, source))
    createEntranceTarget(sh)
    createExitTarget(sh)
end)



