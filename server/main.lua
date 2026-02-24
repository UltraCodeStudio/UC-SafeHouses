
local SafeHouse = require 'server.SafeHouseClass'
Wait(1000)
local sh = SafeHouse:new(1, nil, 1, 'test_safehouse', vector4(135.26, -2203.44, 7.31, 282), vector4(196.83, -1494.21, 29.14, 323))

sh:addUpgrade("test")
sh:addUpgrade('vault', { level = 1, unlocked = true })
if sh:hasUpgrade('vault') then
    --print(sh.id, sh.owner, sh.tier, 'Vault upgrade installed!')
end

sh:playerEnter(1)
Wait(2000)
sh:playerExit(1)