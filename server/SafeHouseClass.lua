---@class SafeHouse : OxClass
---@field owner number
---@field upgrades table<string, boolean>
---@field tier integer
---@field id string
---@field data table<string, any>
local SafeHouse = lib.class('SafeHouse')

---@param owner number
---@param upgrades table<string, boolean>?
---@param tier integer?
---@param id string?
---@param data table<string, any>?
function SafeHouse:constructor(owner, upgrades, tier, id, data)
    self.owner = owner
    self.id = id or ('safehouse_%s'):format(owner)
    self.upgrades = upgrades or {}
    self.tier = tier or 1
    self.data = data or {}
end

function SafeHouse:hasUpgrade(name)
    return self.upgrades[name] == true
end

function SafeHouse:addUpgrade(name)
    self.upgrades[name] = true
end

function SafeHouse:removeUpgrade(name)
    self.upgrades[name] = nil 
end

function SafeHouse:upgradeTier()
    self.tier += 1
end

function SafeHouse:serialize()
    return {
        owner = self.owner,
        upgrades = self.upgrades,
        tier = self.tier,
        id = self.id,
        data = self.data
    }
end

return SafeHouse
