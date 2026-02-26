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

function ShowUpgradesMenu(sh)
    local options = {
        name = sh.id .. "_upgrades_menu",
        title = "Safehouse Upgrades",
        elements = {
            {
                title = "Upgrade Vault",
                description = "Upgrade your vault to increase storage capacity.",
                onSelect = function()
                    print('Upgrade vault option selected for ' .. sh.id)
                end
            },
            {
                title = "Install Security Cameras",
                description = "Install security cameras around your safehouse.",
                onSelect = function()
                    print('Install security cameras option selected for ' .. sh.id)
                end
            },
            {
                title = "Reinforce Door",
                description = "Upgrade your door to be more resistant to break-ins.",
                onSelect = function()
                    print('Reinforce door option selected for ' .. sh.id)
                end
            },
            {
                title = "Close Menu",
                description = "Close the upgrades interface.",
                onSelect = function()
                    print('Close menu option selected for ' .. sh.id)
                end
            }
        }
    }
    ShowMenu(options)
end