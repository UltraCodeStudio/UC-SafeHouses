Config = {}

Config.Debug = true

Config.ControlLaptop = {
    model = 'v_corp_desksetb', 
}

Config.Safe = {
    model = 'xm3_prop_xm3_safe_01a', 
}

Config.Upgrades = {
    vault = {
        label = "Vault",
        description = "A secure vault to store your valuables.",
        [1] = {
            inventorySlots = 10,
            inventoryWeight = 100.0,
            model = 'reh_prop_reh_box_wood01a',
        },
        [2] = {
            inventorySlots = 15,
            inventoryWeight = 150.0,
            model = 'v_med_storage',
        },
        [3] = {
            inventorySlots = 20,
            inventoryWeight = 200.0,
            model = 'xm3_prop_xm3_safe_01a',
        },
    },
    securityCameras = {
        label = "Security Cameras",
        description = "Install security cameras around your safehouse.",
    },
    reinforcedDoor = {
        label = "Reinforced Door",
        description = "Upgrade your door to be more resistant to break-ins.",
    }
}

Config.SafeHouseTiers = {
    [1] = {
        price = 100000,
        upgrades = {
            vault = {minLevel = 1, maxLevel = 3}
        }
    },
    [2] = {
        price = 250000,
        upgrades = {
            vault = {minLevel = 2, maxLevel = 4},
            securityCameras = {minLevel = 1, maxLevel = 2},
        }
    },
    [3] = {
        price = 500000,
        upgrades = {
            vault = {minLevel = 3, maxLevel = 5},
            securityCameras = {minLevel = 2, maxLevel = 3},
            reinforcedDoor = {minLevel = 1, maxLevel = 1},
        },
    }
}