
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
            }
        }
    })
end