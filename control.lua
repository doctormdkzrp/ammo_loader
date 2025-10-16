-- require("__debugadapter__/debugadapter.lua")
-- Mod = require("lib/Import")
protoNames = require "prototypes/names"

-- fGui = require "__flib__.gui"
-- fGui = require "stdlib.gui"
-- require "__core__/lualib/util"
require "stdlib.util"
require "lib/Hash"
Enum = require "lib/Enum"
require "lib/util"
require "lib/gSettings"
require "lib/Initializer"
require "lib/Version"
require "lib/ModCompat"

require "lib/EntDB"

require "lib/Remote"
require "lib/Handlers"

require "lib/ItemDB"

require "lib/gui/Gui"
require "lib/gui/GuiChests"
require "lib/gui/GuiStyles"
require "lib/gui/GuiSettings"
require "lib/gui/GuiSlots"

-- require "lib/gui/GuiTemplates"
-- require "lib/gui/GuiHandlers"

require "lib/createdQ"
require "lib/DB"
require "lib/EntQ"
require "lib/idQ"
require "lib/ProviderRegistry"

require "lib/Force"
require "lib/TrackedSlot"
require "lib/TrackedChest"
require "lib/TrackedChestRetriever"
require "lib/HiddenInserter"

-- Init.registerFunc(
--     -- _init
--     function()
--         storage["trackedPlayers"] = {}
--         local tp = storage["trackedPlayers"]
--         for pInd, player in pairs(game.players) do
--             if (player.surface.name == "nauvis") then
--                 tp[pInd] = player.position
--             end
--         end
--     end
-- )
-- function trackedPlayers()
--     return storage["trackedPlayers"]
-- end
-- function trackedPos(playerInd)
--     return trackedPlayers()[playerInd]
-- end

---@class ItemStack
---@field name string
---@field count integer

---@class Position
---@field x number
---@field y number

-- -@class dbObject
-- -@field isValid fun(self:dbObject):boolean
-- -@field destroy fun(self:dbObject) Does cleanup then removes object from database.
