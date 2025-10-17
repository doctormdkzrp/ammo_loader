local names = {
    gui = {
        itemRankRoot = "ammo_loader_settings_window"
    },
    chests = {
        loader = "ammo-loader-chest",
        requester = "ammo-loader-chest-requester",
        -- requester2 = "ammo-loader-chest-requester-2",
        storage = "ammo-loader-chest-storage",
        passiveProvider = "ammo-loader-chest-passive-provider"
    },
    tech = {
        loader = "ammo-loader-tech-loader-chest",
        requester = "ammo-loader-tech-requester-chest",
        vehicles = "ammo-loader-tech-vehicles",
        burners = "ammo-loader-tech-burners",
        artillery = "ammo-loader-tech-artillery",
        upgrade = "ammo-loader-tech-upgrade",
        returnItems = "ammo-loader-tech-return-items"
    },
    settings = {
        useCartridges = "ammo-loader-setting-use-cartridges",
        bypassResearch = "ammo_loader_bypass_research",
        allowDifferentSurfaces = "ammo-loader-setting-different-surfaces",
        doBurerStructures = "ammo_loader_fill_burner_structures",
        doArtillery = "ammo_loader_fill_artillery",
        doTrains = "ammo_loader_fill_locomotives",
        providedSlotsPerTick = "ammo_loader_provided_slots_per_tick",
        providedSlotsFillLimit = "ammo_loader_provided_slots_fill_limit",
        itemFillSize = "ammo_loader_item_fill_size",
        slotsCheckBestPerTick = "ammo_loader_slots_check_best_per_tick",
        repairToolStackSize = "ammo_loader_repair_tool_stack_size",
        enabled = "ammo_loader_enabled",
        highlightSlots = "ammo_loader_highlight_selected_consumer",
        ignoreLogisticTurrets = "ammo_loader_ignore_logistic_turrets",
        debug = "ammo_loader_debugging",
        debugValues = {
            off = "off",
            important = "important",
            all = "debugging"
        },
        crossSurfaces = "ammo_loader_provide_all_surfaces"
    },
    keys = {
        filterWindow = "ammo-loader-key-filter-window",
        resetMod = "ammo-loader-key-reset",
        returnItems = "ammo-loader-key-return",
        toggleEnabled = "ammo-loader-key-toggle-enabled",
        toggleChestRange = "ammo-loader-key-toggle-chest-ranges",
        manualScan = "ammo-loader-key-manual-scan"
    },
    customInputs = {
        cursorPos = "ammo-loader-key-cursor-position",
        e = "ammo-loader-key-e",
        mouseLeftClick = "ammo-loader-mouse-left-click",
        escape = "ammo-loader-key-escape"
    },
    tips = {
        ammoLoaderCategory = "ammo-loader-tips-category",
        introduction = "ammo-loader-tip-introduction"
    },
    sprites = {
        entities = {
            basicLoaderChest = "ammo-loader-sprite-entity-basic-loader-chest",
            storageLoaderChest = "ammo-loader-sprite-entity-storage-loader-chest",
            requesterLoaderChest = "ammo-loader-sprite-entity-requester-loader-chest",
            old = {
                basicLoaderChest = "ammo-loader-sprite-entity-basic-loader-chest-old"
            }
        },
        icons = {
            overlay = "ammo-loader-sprite-icon-overlay"
        },
        technology = {},
        thumbnail = "ammo-loader-sprite-thumbnail"
    },
    imgPaths = {
        graphics = "__ammo-loader__/graphics",
        entityGraphics = "__ammo-loader__/graphics/entity",
        iconGraphics = "__ammo-loader__/graphics/icon",
        techGraphics = "__ammo-loader__/graphics/technology",
        thumbnail = "__ammo-loader__/graphics/thumbnail.png",
        entities = {
            chestShadow = "__ammo-loader__/graphics/entity/ammo_shadow.png",
            chestMask = "__ammo-loader__/graphics/entity/mask.png",
            chestHrMask = "__ammo-loader__/graphics/entity/hr-mask.png",
            basicChest = "__ammo-loader__/graphics/entity/ammo_albedo.png",
            requesterChest = "__ammo-loader__/graphics/entity/ammo_albedo_b.png",
            storageChest = "__ammo-loader__/graphics/entity/ammo_albedo_y.png",
            passiveProviderChest = "__ammo-loader__/graphics/entity/ammo_albedo_r.png",
            chestOutline = "__ammo-loader__/graphics/entity/ammo_ao.png",
            old = {
                basicChest = "__ammo-loader__/graphics/entity/ammo-loader-chest.png",
                storageChest = "__ammo-loader__/graphics/entity/ammo-loader-chest-storage.png",
                passiveProviderChest = "__ammo-loader__/graphics/entity/ammo-loader-chest-passive-provider.png",
                requesterChest = "__ammo-loader__/graphics/entity/ammo-loader-chest-requester.png"
            }
        },
        icons = {
            basicChest = "__ammo-loader__/graphics/icon/chest.png",
            requesterChest = "__ammo-loader__/graphics/icon/chest_b.png",
            storageChest = "__ammo-loader__/graphics/icon/chest_y.png",
            passiveProviderChest = "__ammo-loader__/graphics/icon/chest_r.png",
            solo = "__ammo-loader__/graphics/icon/solo.png",
            old = {
                basicChest = "__ammo-loader__/graphics/icon/ammo-loader-chest.png",
                requesterChest = "__ammo-loader__/graphics/icon/ammo-loader-chest-requester.png",
                storageChest = "__ammo-loader__/graphics/icon/ammo-loader-chest-storage.png",
                passiveProviderChest = "__ammo-loader__/graphics/icon/ammo-loader-chest-passive-provider.png"
            },
            overlay = "__ammo-loader__/graphics/icon/ammo-loader-icon-overlay.png"
        },
        technology = {
            main = "__ammo-loader__/graphics/icon/technology.png"
        }
    },
    mods = {
        repairTurret = "Repair_Turrets",
    },
    -- loaderChest = "ammo-loader-chest",
    -- requesterChest = "ammo-loader-chest-requester",
    -- requesterChest2 = "ammo-loader-chest-requester-2",
    -- storageChest = "ammo-loader-chest-storage",
    hiddenInserter = "ammo-loader-hidden-inserter",
    itemSubgroup = "ammo-loader-items",
    superFuel = "ammo-loader-superfuel",
    rangeIndicator = "ammo-loader-range-indicator",
    iconOverlay = "ammo-loader-icon-overlay",
    bulletCaseIcon = "ammo-loader-icon-bullet-case",
    ammoPrefix = "ammo-loader-ammo-",
    ammoSubgroup = "ammo-loader-subgroup-ammo",
    fuelSubgroup = "ammo-loader-subgroup-fuel",
    cartridgePrefix = "ammo-loader-cartridge-",
    cartridgeNameKey = "ammo-loader-cartridge-prefix",
    cartridgeDescriptionKey = "ammo-loader-cartridge",
    cartridgeItemGroup = "ammo-loader-cartridge-group",
    cartridgeAmmoSubgroup = "ammo-loader-cartridge-subgroup-ammo",
    cartridgeFuelSubgroup = "ammo-loader-cartridge-subgroup-fuel",
    rangeExtender = "ammo-loader-range-extender"
}
return names
