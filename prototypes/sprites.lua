local protoNames = require("prototypes.names")
local sprites = {}
local alSprites = sprites

alSprites.entities = {}
alSprites.icons = {}
alSprites.technology = {}

alSprites.entities.basicLoaderChest = {
    type = "sprite",
    name = protoNames.sprites.entities.basicLoaderChest,
    filename = protoNames.imgPaths.entities.basicChest,
    priority = "extra-high",
    width = 45,
    height = 32,
    frame_count = 1,
    shift = { 0.1875, 0 },
    -- scale = 1,
    hr_version = {
        filename = protoNames.imgPaths.entities.basicChest,
        priority = "extra-high",
        width = 45,
        height = 32,
        frame_count = 1,
        shift = { 0.1875, 0 },
        scale = 1
    }
}
alSprites.entities.oldBasicLoaderChest = {
    type = "sprite",
    name = protoNames.sprites.entities.old.basicLoaderChest,
    filename = protoNames.imgPaths.entities.old.basicChest,
    priority = "extra-high",
    width = 45,
    height = 32,
    frame_count = 1,
    shift = { 0.1875, 0 },
    -- scale = 1,
    hr_version = {
        filename = protoNames.imgPaths.entities.old.basicChest,
        priority = "extra-high",
        width = 45,
        height = 32,
        frame_count = 1,
        shift = { 0.1875, 0 },
        scale = 1
    }
}
alSprites.icons.overlay = {
    type = "sprite",
    name = protoNames.sprites.icons.overlay,
    filename = protoNames.imgPaths.icons.overlay,
    priority = "extra-high",
    width = 12,
    height = 12,
    frame_count = 1,
    shift = { 0.1875, 0 },
    -- scale = 1,
    hr_version = {
        filename = protoNames.imgPaths.icons.overlay,
        priority = "extra-high",
        width = 12,
        height = 12,
        frame_count = 1,
        shift = { 0.1875, 0 },
        scale = 1
    }
}
alSprites.icons.thumbnail = {
    type = "sprite",
    name = protoNames.sprites.thumbnail,
    filename = protoNames.imgPaths.thumbnail,
    priority = "extra-high",
    width = 144,
    height = 144,
    frame_count = 1,
    -- scale = 1,
    hr_version = {
        filename = protoNames.imgPaths.thumbnail,
        priority = "extra-high",
        width = 144,
        height = 144,
        frame_count = 1,
        scale = 1
    }
}

for spriteTypeName, spriteList in pairs(alSprites) do
    -- local extendList = {}
    for protoName, proto in pairs(spriteList) do
        -- table.insert(extendList, proto)
        data:extend { proto }
    end
    -- data:extend(extendList)
end
