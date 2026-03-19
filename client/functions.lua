
---Create an ox_target box zone.
---@param data table
---@param data.coords vector3 REQUIRED
---@param data.name string|nil Optional zone name (useful for removal)
---@param data.size vector3|nil
---@param data.rotation number|nil
---@param data.debug boolean|nil
---@param data.label string
---@param data.icon string|nil
---@param data.distance number|nil
---@param data.onSelect fun(targetData: table)|nil
---@return number zoneId
function CreateBoxTarget(data)
    exports.ox_target:removeZone(data.name)
    return exports.ox_target:addBoxZone({
        name = data.name,
        coords = data.coords,
        size = data.size or vec3(1.0, 1.0, 2.0),
        rotation = data.rotation or 0.0,
        debug = data.debug or false,
        options = {
            {
                name = (data.name or 'zone') .. '_option',
                label = data.label,
                icon = data.icon or 'fas fa-door-open',
                distance = data.distance or 2.0,
                onSelect = data.onSelect or function(_) end,
                canInteract = data.canInteract or nil,
            }
        }
    })
end

---@param ent number Entity handle (must exist on THIS client)
---@param data table
---@param data.name string|nil Option identifier (used for removal)
---@param data.label string
---@param data.icon string|nil
---@param data.distance number|nil
---@param data.onSelect fun(targetData: table)|nil
function AddLocalEntity(ent, data)
    if not ent or ent == 0 or not DoesEntityExist(ent) then
        print('[AddLocalEntity] invalid entity', ent)
        return false
    end

    return exports.ox_target:addLocalEntity(ent, data)
end

function ShowMenu(options)
    lib.registerContext({
        id = options.id or 'example_menu',
        title = options.title or 'Example Menu',
        options = options.elements or {},
        onSelect = options.onSelect or function(selected, args)
            print('Selected option:', selected.value)
        end,
    })
    lib.showContext(options.id or 'example_menu')
end