

function ShowLaptopMenu(sh)
    local options = {
        name = sh.id .. "_laptop_menu",
        title = "Safehouse Control Laptop",
        elements = {
            {
                title = "Manage Upgrades",
                description = "View and manage your current safehouse upgrades.",
                onSelect = function()
                    ShowUpgradesMenu(sh)
                end
            },
            {
                title = "Close Menu",
                description = "Close the laptop interface.",
                onSelect = function()
                    print('Close menu option selected for ' .. sh.id)
                end
            }
        }
    }
    ShowMenu(options)
    
end

---@param sh table
function ShowUpgradesMenu(sh)
    lib.registerContext({
        id = ('%s_upgrades_menu'):format(sh.id),
        title = ('%s - Upgrades'):format(sh.id),
        options = {
            {
                title = 'Vault Upgrade',
                description = 'Increase storage capacity and improve protection for valuables.',
                icon = 'vault',
                onSelect = function()
                    TriggerServerEvent('uc-safehouses:server:addUpgrade', sh.id ,'vault', 2)
                end
            },
            {
                title = 'Security Cameras',
                description = 'Install internal and external cameras for surveillance coverage.',
                icon = 'video',
                onSelect = function()
                    TriggerServerEvent('uc-safehouses:server:addUpgrade', 'vault', 2)
                end
            },
            {
                title = 'Prison Cells',
                description = 'Add holding cells for captured targets or roleplay scenarios.',
                icon = 'lock',
                onSelect = function()
                    HandleSafehouseUpgrade(sh, 'prison_cells')
                end
            },
            {
                title = 'Torture Room',
                description = 'Build an interrogation room for darker criminal operations.',
                icon = 'user-secret',
                onSelect = function()
                    HandleSafehouseUpgrade(sh, 'torture_room')
                end
            },
            {
                title = 'Crafting Station',
                description = 'Install a workbench for crafting weapons, tools, or supplies.',
                icon = 'hammer',
                onSelect = function()
                    HandleSafehouseUpgrade(sh, 'crafting_station')
                end
            },
            {
                title = 'Close Menu',
                description = 'Exit the upgrades interface.',
                icon = 'xmark',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })

    lib.showContext(('%s_upgrades_menu'):format(sh.id))
end


---@class SafehouseDraft
---@field owner string
---@field tier number
---@field id string
---@field iplExitCoords string
---@field iplEnterCoords string
---@field controlLaptopCoords string
---@field safeCoords string

---@type SafehouseDraft
local safehouseDraft = {
    owner = '',
    tier = 1,
    id = '',
    iplExitCoords = '',
    iplEnterCoords = '',
    controlLaptopCoords = '',
    safeCoords = '',
}

---@param coords vector3
---@param heading number
---@return string
local function formatVector4(coords, heading)
    return ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, heading)
end

---@param input string|nil
---@return vector4
local function parseVector4(input)
    assert(type(input) == 'string' and input ~= '', 'Invalid vector4 input')

    local x, y, z, w = input:match('vector4%(%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*%)')

    if not x then
        x, y, z, w = input:match('([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)')
    end

    assert(x and y and z and w, ('Invalid vector4 format: %s'):format(input))

    return vector4(tonumber(x), tonumber(y), tonumber(z), tonumber(w))
end

---@param title string
---@param current string
---@param cb fun(value: string)
local function inputText(title, current, cb)
    local result = lib.inputDialog(title, {
        {
            type = 'input',
            label = title,
            required = true,
            default = current
        }
    })

    if not result or not result[1] then return end
    cb(result[1])
end

---@param title string
---@param current number
---@param cb fun(value: number)
local function inputNumber(title, current, cb)
    local result = lib.inputDialog(title, {
        {
            type = 'number',
            label = title,
            required = true,
            default = current
        }
    })

    if not result or not result[1] then return end
    cb(tonumber(result[1]) or current)
end

---@param field '"iplExitCoords"'|'"iplEnterCoords"'|'"controlLaptopCoords"'|'"safeCoords"'
local function setCoordsFromPlayer(field)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    safehouseDraft[field] = formatVector4(coords, heading)

    lib.notify({
        title = 'Safehouse Creator',
        description = ('Saved %s from your current position'):format(field),
        type = 'success'
    })
end

local function resetSafehouseDraft()
    safehouseDraft = {
        owner = '',
        tier = 1,
        id = '',
        iplExitCoords = '',
        iplEnterCoords = '',
        controlLaptopCoords = '',
        safeCoords = '',
    }
end

local function createSafehouseFromDraft()
    local ok, result = pcall(function()
        return {
            owner = safehouseDraft.owner,
            tier = safehouseDraft.tier,
            id = safehouseDraft.id,
            iplExitCoords = parseVector4(safehouseDraft.iplExitCoords),
            iplEnterCoords = parseVector4(safehouseDraft.iplEnterCoords),
            controlLaptopCoords = parseVector4(safehouseDraft.controlLaptopCoords),
            safeCoords = parseVector4(safehouseDraft.safeCoords),
        }
    end)

    if not ok then
        lib.notify({
            title = 'Safehouse Creator',
            description = result,
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('uc-safehouses:server:createSafeHouse', result)
end

function OpenSafehouseCreator()
    lib.registerContext({
        id = 'safehouse_creator_menu',
        title = 'Safehouse Creator',
        options = {
            {
                title = 'Owner Citizen ID',
                description = safehouseDraft.owner ~= '' and safehouseDraft.owner or 'Not set',
                icon = 'user',
                onSelect = function()
                    inputText('Owner Citizen ID', safehouseDraft.owner, function(value)
                        safehouseDraft.owner = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Tier',
                description = tostring(safehouseDraft.tier),
                icon = 'layer-group',
                onSelect = function()
                    inputNumber('Tier', safehouseDraft.tier, function(value)
                        safehouseDraft.tier = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Safehouse ID',
                description = safehouseDraft.id ~= '' and safehouseDraft.id or 'Not set',
                icon = 'hashtag',
                onSelect = function()
                    inputText('Safehouse ID', safehouseDraft.id, function(value)
                        safehouseDraft.id = value
                        OpenSafehouseCreator()
                    end)
                end
            },

            {
                title = 'IPL Exit Coords',
                description = safehouseDraft.iplExitCoords ~= '' and safehouseDraft.iplExitCoords or 'Not set',
                icon = 'arrow-right-from-bracket',
                onSelect = function()
                    inputText('IPL Exit Coords', safehouseDraft.iplExitCoords, function(value)
                        safehouseDraft.iplExitCoords = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Use Current Position for IPL Exit',
                description = 'Auto-fill from your current location and heading',
                icon = 'crosshairs',
                onSelect = function()
                    setCoordsFromPlayer('iplExitCoords')
                    OpenSafehouseCreator()
                end
            },

            {
                title = 'IPL Enter Coords',
                description = safehouseDraft.iplEnterCoords ~= '' and safehouseDraft.iplEnterCoords or 'Not set',
                icon = 'arrow-right-to-bracket',
                onSelect = function()
                    inputText('IPL Enter Coords', safehouseDraft.iplEnterCoords, function(value)
                        safehouseDraft.iplEnterCoords = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Use Current Position for IPL Enter',
                description = 'Auto-fill from your current location and heading',
                icon = 'crosshairs',
                onSelect = function()
                    setCoordsFromPlayer('iplEnterCoords')
                    OpenSafehouseCreator()
                end
            },

            {
                title = 'Control Laptop Coords',
                description = safehouseDraft.controlLaptopCoords ~= '' and safehouseDraft.controlLaptopCoords or 'Not set',
                icon = 'laptop',
                onSelect = function()
                    inputText('Control Laptop Coords', safehouseDraft.controlLaptopCoords, function(value)
                        safehouseDraft.controlLaptopCoords = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Use Current Position for Control Laptop',
                description = 'Auto-fill from your current location and heading',
                icon = 'crosshairs',
                onSelect = function()
                    setCoordsFromPlayer('controlLaptopCoords')
                    OpenSafehouseCreator()
                end
            },

            {
                title = 'Safe Coords',
                description = safehouseDraft.safeCoords ~= '' and safehouseDraft.safeCoords or 'Not set',
                icon = 'vault',
                onSelect = function()
                    inputText('Safe Coords', safehouseDraft.safeCoords, function(value)
                        safehouseDraft.safeCoords = value
                        OpenSafehouseCreator()
                    end)
                end
            },
            {
                title = 'Use Current Position for Safe',
                description = 'Auto-fill from your current location and heading',
                icon = 'crosshairs',
                onSelect = function()
                    setCoordsFromPlayer('safeCoords')
                    OpenSafehouseCreator()
                end
            },

            {
                title = 'Create Safehouse',
                description = 'Create the safehouse using the current draft values',
                icon = 'check',
                onSelect = function()
                    createSafehouseFromDraft()
                end
            },
            {
                title = 'Reset Draft',
                description = 'Clear all saved values from the creator',
                icon = 'trash',
                onSelect = function()
                    resetSafehouseDraft()
                    OpenSafehouseCreator()
                end
            }
        }
    })

    lib.showContext('safehouse_creator_menu')
end

RegisterCommand('createsafehouse', function()
    OpenSafehouseCreator()
end, false)


