local names = require("prototypes.names")
local util = require("prototypes.util")

local tempIronChest = data.raw["recipe"]["iron-chest"]
if (not tempIronChest) then
    tempIronChest = {
        type = "recipe",
        name = "iron-chest",
        enabled = true,
        ingredients = {
            {type = "item", name = "iron-plate", amount = 8},
        }
    }
end

local recipes = {}
local startEnabled = settings.startup[names.settings.bypassResearch].value
local filterInserterName = "bulk-inserter"
if (data.raw["item"]["yellow-bulk-inserter"]) then
    filterInserterName = "yellow-bulk-inserter"
end
local chestIngredient = {type = "item", name = "electronic-circuit", amount = 20}
if (data.raw["item"]["copper-motor"]) then
    chestIngredient = {type = "item", name = "copper-motor", amount = 2}
end

local function singleItemResultTable(name, amt)
    local res = {type="item", name=name, amount=amt}
    return {res}
end

recipes.ammoLoader =
    util.modifiedEnt(
    tempIronChest,
    {
        type = "recipe",
        name = names.chests.loader,
        enabled = startEnabled,
        energy_required = 2,
        results = singleItemResultTable(names.chests.loader, 1),
        icon = util.filePath(names.chests.loader, "icon"),
        icon_size = 32,
    },
    {
        ingredients = {
            chestIngredient,
            {type = "item", name = "iron-chest", amount = 1},
            {type = "item", name = "burner-inserter", amount = 5}
        }
    }
)
recipes.requester1 =
    util.modifiedEnt(
    data.raw["recipe"]["requester-chest"],
    {
        type = "recipe",
        name = names.chests.requester,
        enabled = startEnabled,
        energy_required = 2,
        results = singleItemResultTable(names.chests.requester, 1),
        icon = util.filePath(names.chests.requester, "icon"),
        icon_size = 32,
    },
    {
        ingredients = {
            {type = "item", name = "requester-chest", amount = 2},
            {type = "item", name = filterInserterName, amount = 5}
        }
    }
)
recipes.storage =
    util.modifiedEnt(
    data.raw["recipe"]["storage-chest"],
    {
        type = "recipe",
        name = names.chests.storage,
        enabled = startEnabled,
        results = singleItemResultTable(names.chests.storage, 1),
        icon = util.filePath(names.chests.storage, "icon"),
        icon_size = 32,
    },
    {
        ingredients = {
            {type = "item", name = "wooden-chest", amount = 10},
            chestIngredient
        }
    }
)
recipes.passiveProvider =
    util.modifiedEnt(
    data.raw["recipe"]["passive-provider-chest"],
    {
        type = "recipe",
        name = names.chests.passiveProvider,
        enabled = startEnabled,
        energy_required = 2,
        results = singleItemResultTable(names.chests.passiveProvider, 1),
        icon = util.filePath(names.chests.passiveProvider, "icon"),
        icon_size = 32,
    },
    {
        ingredients = {
            {type = "item", name = "passive-provider-chest", amount = 2},
            {type = "item", name = filterInserterName, amount = 5},
        }
    }
)
-- recipes.testAmmo = {
--     type = "recipe",
--     name = "testAmmo",
--     enabled = true,
--     energy_required = 1,
--     result = "testAmmo",
--     ingredients = {
--         {"iron-plate", 1}
--     }
-- }

for k, v in pairs(recipes) do
    data:extend {v}
end
