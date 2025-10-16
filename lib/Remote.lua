Rem = {}
Rem.interfaceName = "ammo-loader"

Rem.funcs = {}

function Rem.funcs.printItemDB(args)
    local printList = {}
    for name, item in pairs(ItemDB.items()) do
        local doPrint = true
        if (args) then
            doPrint = false
            if (args.item) and (args.item == name) then
                doPrint = true
            end
            if (args.category) and (args.category == item.category) then
                doPrint = true
            end
        end
        if (doPrint) then
            -- inform(concat(name, "-> category: ", item.category, ", score: ", item.score, ", rank: ", item.rank), true)
            Array.insert(printList, item)
        end
    end
    table.sort(printList, ItemDB.compare)
    for i = 1, #printList do
        local item = printList[i]
        -- inform(concat(item.name, "-> category: ", item.category, ", score: ", item.score, ", rank: ", item.rank), true)
        ctInform("category: ", item.category, ", rank: ", item.rank, ", score: ", item.score, ", name: ", item.name)
    end
    ctInform(#printList, " items printed.")
end

function Rem.funcs.printNumTracked(forceName)
    local total = 0
    local tSlots = 0
    local tInserters = 0
    local tChests = 0
    local tStorage = 0
    local forces = Force.forces()
    local f = Force.get(forceName)
    if forceName and f then
        forces = { forceName = f }
    end
    for name, force in pairs(Force.forces()) do
        local amtSlots = 0
        local amtInserters = 0
        for slot in force.slots:slotIter() do
            amtSlots = amtSlots + 1
            if (isValid(slot:inserterEnt())) then
                amtInserters = amtInserters + 1
            end
        end
        -- local amtSlots = force.slots:size()
        -- for slot in force:iterSlots() do
        --     amtSlots = amtSlots + 1
        -- end
        -- local amtInserters = #util.allFind({force = forceName, name = HI.protoName})
        local amtChests = force.chests:size()
        local amtStorage = force.storageChests:size()
        local amtT = amtSlots + amtChests + amtStorage
        ctInform(
            "Force ",
            name,
            ": ",
            amtT,
            " total, ",
            amtSlots,
            " slots, ",
            amtInserters,
            " inserters, ",
            amtChests,
            " chests, ",
            amtStorage,
            " storage chests"
        )
        tSlots = tSlots + amtSlots
        -- tInserters = tInserters + amtInserters
        tChests = tChests + amtChests
        tStorage = tStorage + amtStorage
    end
end

function Rem.funcs.printNumProvided(forceName)
    forceName = forceName or "player"
    local force = Force.get(forceName)
    if (not force) then
        return
    end
    local nProv = force.providedSlots:size()
    ctInform("Force ", forceName, ": ", nProv, " provided")
end

function Rem.funcs.purgeData()
    HI.destroyOrphans2()
    cInform("finish destroy orphans")
    -- EntDB.purgeTracked()
    -- cInform("finish purge tracked")
end

Rem.funcs.on_entity_replaced = function(data)
    Handlers.onBuilt({ created_entity = data.new_entity })
end

Rem.funcs.creative_mode_reloadMods = function()
    -- Profiler.Stop()
    game.reload_mods()
    cInform("reloaded mods")
end

Rem.funcs.creative_mode_disableProfiling = function()
    gSets._canUseProfiler = false
    -- Profiler.Stop()
    cInform("disabled profiling")
end

Rem.funcs.creative_mode_enableProfiling = function()
    gSets._canUseProfiler = true
    cInform("enabled profiling")
end

Rem.funcs.creative_mode_updateBreakpoints = function()
    if (game.active_mods["debugadapter"]) then
        remote.call("debugadapter", "updateBreakpoints")
    end
end

-- Rem.funcs.informatron_menu = function(data)
--     return alGui.informatronMenu(data.player_index)
-- end
-- Rem.funcs.informatron_page_content = function(data)
--     return alGui.informatronPageContent(data.page_name, data.player_index, data.element)
-- end
-- Rem.funcs.informatron_open_to_page = function(data)
--     if data.player_index and data.interface and data.page_name then
--         --   return Informatron.open_main_window(data.player_index, {interface=data.interface, page_name=data.page_name})
--         cInform("open to page?")
--     end
-- end

Rem.funcs.cheatMode = function()
    local player = game.player ---@type LuaPlayer
    if (not isValid(player)) then
        return
    end
    local char = player.character
    if (isValid(char)) then
        char.character_inventory_slots_bonus = 200
        char.character_item_drop_distance_bonus = 2000
        char.character_item_pickup_distance_bonus = 320
        char.character_loot_pickup_distance_bonus = 320
        char.character_build_distance_bonus = 2000
        char.character_reach_distance_bonus = 2000
        char.character_resource_reach_distance_bonus = 2000
        char.character_running_speed_modifier = 7
        char.cheat_mode = true
        char.destructible = false
        local force = player.force ---@type LuaForce
        if (isValid(force)) then
            force.research_all_technologies(true)
            force.enable_all_recipes()
        end
    end
end

function Rem.funcs.testSprite(name)
    if (not name) then
        name = protoNames.sprites.entities.basicLoaderChest
    end
    local player = game.player ---@type LuaPlayer
    if (not isValid(player)) or (not isValid(player.character)) then
        return
    end
    rendering.draw_sprite {
        sprite = name,
        surface = player.surface,
        target = player.character,
        players = { player },
        time_to_live = 180
    }
end

remote.add_interface("ammo-loader", Rem.funcs)

return Rem
