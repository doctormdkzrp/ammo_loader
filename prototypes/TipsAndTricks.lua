---@class alTips
-- alTips = {}

local protoNames = require("prototypes.names")

data:extend {
    {
        type = "tips-and-tricks-item-category",
        name = protoNames.tips.ammoLoaderCategory,
        order = "a-[ammo_loader]"
    },
    {
        type = "tips-and-tricks-item",
        name = protoNames.tips.introduction,
        category = protoNames.tips.ammoLoaderCategory,
        order = "a",
        is_title = true,
        -- trigger = {type = "unlocked-recipe", recipe = protoNames.chests.loader},
        trigger = { type = "dependencies-met" },
        image = protoNames.imgPaths.thumbnail
    }
}
