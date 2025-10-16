local names = require("prototypes.names")
local util = require("prototypes.util")
local Map = require("stdlib.Map")

local ammoTypes = {}
ammoTypes["car"] = 1
ammoTypes["ammo-turret"] = 1
ammoTypes["artillery-wagon"] = 1
ammoTypes["artillery-turret"] = 1
-- ammoTypes["character"] = 1
ammoTypes["spider-vehicle"] = 1

local function allowCopyPaste()
    local protos = {}
    local protoNames = {}
    local burnerProtoNames = {}
    for typeName, typeObj in pairs(data.raw) do
        for protoName, proto in pairs(typeObj) do
            if (proto) and ((proto.energy_source and proto.energy_source.type == "burner") or (ammoTypes[typeName])) then
                if (proto.energy_source and proto.energy_source.type == "burner") then
                    table.insert(burnerProtoNames, protoName)
                end
                local info = { type = typeName, name = protoName }
                table.insert(protos, info)
                table.insert(protoNames, protoName)
            end
        end
    end
    for i, protoInfo in pairs(protos) do
        local proto = data.raw[protoInfo.type][protoInfo.name]
        if (proto ~= nil) then
            data.raw[protoInfo.type][protoInfo.name].allow_copy_paste = true
            local adds = data.raw[protoInfo.type][protoInfo.name].additional_pastable_entities
            if (not adds) then
                data.raw[protoInfo.type][protoInfo.name].additional_pastable_entities = { protoInfo.name }
            elseif (not table.containsValue(adds, protoInfo.name)) then
                table.insert(adds, protoInfo.name)
            end
        end
    end
end
allowCopyPaste()

local entities = {}

local chestRadiusSprite = {
    filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
    width = 12,
    height = 12,
    priority = "extra-high-no-scale"
}
-- local chestRadiusSpecification = {
--     sprite = chestRadiusSprite,
--     distance = settings.startup.ammo_loader_chest_radius_startup.value,
--     draw_in_cursor = true,
--     draw_on_selection = true
-- }

local basicAmmoPic = {
    filename = util.filePath(names.chests.loader, "entity"),
    priority = "extra-high",
    width = 45,
    height = 32,
    shift = { 0.1875, 0 },
    -- shift = {0, 0}
    hr_version = {
        filename = util.filePath(names.chests.loader, "entity"),
        priority = "extra-high",
        width = 45,
        height = 32,
        shift = { 0.1875, 0 }
    }
}
-- local basicFuelPic = {
--     filename = "__ammo-loader__/graphics/entity/FuelLoaderChest.png",
--     priority = "extra-high",
--     width = 44,
--     height = 32,
--     shift = {0.1875, 0}
--     --shift = {0, 0}
-- }
local invisInserterPic = util.invisPic
-- local platPic = data.raw["inserter"]["fast-inserter"].platform_picture
local surfConditions =
{
    --   {
    --     property = "gravity",
    --     min = 0.1
    --   }
}

entities.hiddenInserter = util.modifiedEnt(
    data.raw["inserter"]["bulk-inserter"], {
        name = names.hiddenInserter,
        filter_count = 1,
        allow_custom_vectors = true,
        stack_size_bonus = 200,
        -- icon = "nil",
        -- icon_size = 1,
        selection_box = { { 0, 0 }, { 0, 0 } },
        collision_box = { { 0, 0 }, { 0, 0 } },
        -- drawing_box_vertical_extension = {{0, 0}, {0, 0}},
        pickup_position = { -0.5, 0.5 },
        insert_position = { 0.5, 0.5 },
        extension_speed = 100000,
        rotation_speed = 100000,
        energy_source = { type = "void" },
        selectable_in_game = false,
        allow_copy_paste = false,
        next_upgrade = "nil",
        draw_held_item = false,
        draw_inserter_arrow = false,
        hand_size = 0,
        corpse = "nil",
        minable = "nil",
        hidden = true,
    }, {
        collision_mask = { layers = {} },
        flags = {
            "not-on-map", "hide-alt-info", "not-deconstructable",
            "not-repairable", "not-blueprintable", "not-rotatable",
            "not-upgradable", "not-selectable-in-game", "no-copy-paste", "get-by-unit-number"
        },
        surface_conditions = surfConditions,
        platform_picture = { sheet = util.invisPic },
        hand_base_picture = util.invisPic,
        hand_open_picture = util.invisPic,
        hand_closed_picture = util.invisPic,
        hand_base_shadow = util.invisPic,
        hand_open_shadow = util.invisPic,
        hand_closed_shadow = util.invisPic
    })

entities.basicAmmoChest = util.modifiedEnt(data.raw["container"]["iron-chest"],
    {
        name = names.chests.loader,
        minable = { result = names.chests.loader },
        inventory_size = 16,
        icon = util.filePath(names.chests.loader, "entity"),
        icon_size = 32,
        flags = {
            "get-by-unit-number"
        },
    }, {
        surface_conditions = surfConditions,
        -- picture = {
        --     layers = {
        --         {
        --             filename = util.filePath(names.chests.loader, "entity"),
        --             priority = "extra-high",
        --             width = 45,
        --             height = 32,
        --             frame_count = 1,
        --             shift = {0.1875, 0},
        --             -- scale = 1,
        --         }
        --         -- shift = {0, 0}
        --     }
        -- }
        -- radius_visualisation_specification = chestRadiusSpecification
    })

-- entities.basicAmmoChestOld =
--     util.modifiedEnt(
--     data.raw["container"]["iron-chest"],
--     {
--         name = "ammo-loader-chest-old",
--         minable = {result = names.chests.loader},
--         inventory_size = 16
--     },
--     {
--         picture = {
--             layers = {
--                 alDataStage.sprites.entities.oldBasicLoaderChest
--                 --shift = {0, 0}
--             }
--         },
--         radius_visualisation_specification = chestRadiusSpecification
--     }
-- )

entities.requesterChest = util.modifiedEnt(
    data.raw["logistic-container"]["requester-chest"],
    {
        name = names.chests.requester,
        minable = { result = names.chests.requester },
        inventory_size = 32,
        render_not_in_network_icon = false,
        max_logistic_slots = 6,
        icon = util.filePath(names.chests.requester, "entity"),
        icon_size = 32
    }, {
        -- animation = {
        --     layers = {
        --         {
        --             filename = util.filePath(names.chests.requester, "entity"),
        --             priority = "extra-high",
        --             width = 45,
        --             height = 32,
        --             frame_count = 1,
        --             shift = {0.1875, 0},
        --             -- scale = 1,
        --         }
        --         -- shift = {0, 0}
        --     }
        -- }
        -- radius_visualisation_specification = chestRadiusSpecification
    })

entities.storageChest = util.modifiedEnt(
    data.raw["logistic-container"]["storage-chest"],
    {
        name = names.chests.storage,
        minable = { result = names.chests.storage },
        render_not_in_network_icon = false,
        inventory_size = 50,
        icon = util.filePath(names.chests.storage, "entity"),
        icon_size = 32
    }, {
        surface_conditions = surfConditions,
        -- animation = {
        --     layers = {
        --         {
        --             filename = util.filePath(names.chests.storage, "entity"),
        --             priority = "extra-high",
        --             width = 45,
        --             height = 32,
        --             frame_count = 1,
        --             shift = {0.1875, 0},
        --             -- scale = 1,
        --             hr_version = {
        --                 filename = util.filePath(names.chests.storage, "entity"),
        --                 priority = "extra-high",
        --                 width = 45,
        --                 height = 32,
        --                 frame_count = 1,
        --                 shift = {0.1875, 0},
        --                 scale = 1
        --             }
        --         }
        --         -- shift = {0, 0}
        --     }
        -- }
        -- radius_visualisation_specification = chestRadiusSpecification
    })

entities.passiveProviderChest = util.modifiedEnt(
    data.raw["logistic-container"]["passive-provider-chest"],
    {
        name = names.chests.passiveProvider,
        minable = { result = names.chests.passiveProvider },
        inventory_size = 32,
        render_not_in_network_icon = false,
        icon = util.filePath(names.chests.passiveProvider, "entity"),
        icon_size = 32
    }, {
        -- animation = {
        --     layers = {
        --         {
        --             filename = util.filePath(names.chests.passiveProvider,
        --                                      "entity"),
        --             priority = "extra-high",
        --             width = 45,
        --             height = 32,
        --             frame_count = 1,
        --             shift = {0.1875, 0},
        --             -- scale = 1,
        --             hr_version = {
        --                 filename = util.filePath(names.chests.passiveProvider,
        --                                          "entity"),
        --                 priority = "extra-high",
        --                 width = 45,
        --                 height = 32,
        --                 frame_count = 1,
        --                 shift = {0.1875, 0},
        --                 scale = 1
        --             }
        --         }
        --         -- shift = {0, 0}
        --     }
        -- }
        -- radius_visualisation_specification = chestRadiusSpecification
    })

-- local baseAnimation = {
--     layers = {
--         {
--             filename = "__base__/graphics/entity/logistic-chest/storage-chest.png",
--             priority = "extra-high",
--             width = 34,
--             height = 38,
--             frame_count = 7,
--             shift = util.by_pixel(0, -2),
--             hr_version = {
--                 filename = "__base__/graphics/entity/logistic-chest/hr-storage-chest.png",
--                 priority = "extra-high",
--                 width = 66,
--                 height = 74,
--                 frame_count = 7,
--                 shift = util.by_pixel(0, -2),
--                 scale = 0.5
--             }
--         },
--         {
--             filename = "__base__/graphics/entity/logistic-chest/logistic-chest-shadow.png",
--             priority = "extra-high",
--             width = 48,
--             height = 24,
--             repeat_count = 7,
--             shift = util.by_pixel(8.5, 5.5),
--             draw_as_shadow = true,
--             hr_version = {
--                 filename = "__base__/graphics/entity/logistic-chest/hr-logistic-chest-shadow.png",
--                 priority = "extra-high",
--                 width = 96,
--                 height = 44,
--                 repeat_count = 7,
--                 shift = util.by_pixel(8.5, 5),
--                 draw_as_shadow = true,
--                 scale = 0.5
--             }
--         }
--     }
-- }
-- entities.rangeIndicator = {
--     name = names.rangeIndicator,
--     type = "simple-entity",
--     flags = {
--         -- "not-on-map",
--         "not-rotatable",
--         -- "hide-from-bonus-gui",
--         "hide-alt-info",
--         "not-deconstructable",
--         "not-blueprintable",
--         "placeable-off-grid",
--         "not-flammable"
--     },
--     minable = {mining_time = 0, results = {}},
--     selectable_in_game = false,
--     tile_width = 1,
--     tile_height = 1,
--     picture = {
--         filename = util.filePath(names.rangeIndicator, "entity"),
--         priority = "extra-high",
--         width = 32,
--         height = 32
--     },
--     map_color = {r = 0.858, g = 0.301, b = 0.741, a = 0.25}
-- }

for k, v in pairs(entities) do data:extend { v } end
