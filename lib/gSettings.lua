---@class gSets
gSets = {}

---@alias gSettings gSets
gSettings = gSets
gSets.refs = {}

gSets._init = function()
    storage["settings_cache"] = {}
    storage["draw_toggle"] = {
        count = 0
    }
    storage.guiTracker = {}
    storage["gSets"] = {}
    -- storage["definesReverse"] = {events = {}}
    -- for name, id in pairs(defines.events) do
    --     storage.definesReverse.events[id] = name
    --     -- if (id == eName) then
    --     --     return name
    --     -- end
    -- end
    gSets.update()
end

function gSets._onLoad()
    gSets.updateRefs()
end

gSets.cache = function() return storage["settings_cache"] end
-- gCache = gSets.cache
gSets.value = function(name) return gSets.cache()[name] end
gSets.getVal = gSets.value
gSets.val = gSets.value
gSets.lstZeroIsInfinite = {
    ammo_loader_max_items_per_slot = true,
    ammo_loader_max_items_per_inventory = true,
    ammo_loader_chest_radius = true
}
gSets.requireUpdate = {
    ammo_loader_chest_radius = true,
    ammo_loader_enabled = true,
    ammo_loader_performance_mode = true
}
gSets.requireUpdate[protoNames.settings.doBurerStructures] = true
gSets.requireUpdate[protoNames.settings.doArtillery] = true
gSets.requireUpdate[protoNames.settings.doTrains] = true
gSets.requireUpdate[protoNames.settings.crossSurfaces] = true

function gSets.update()
    local c = {}
    storage["settings_cache"] = c

    for k, v in pairs(settings.global) do
        local setName = k
        if (string.find(setName, "ammo_loader")) then
            c[k] = v.value
        end
    end
    c["ammo_loader_bypass_research"] = settings.startup[protoNames.settings.bypassResearch].value

    gSets.updateRefs()
end

function gSets.updateRefs()
    for k, v in pairs(settings.global) do
        local setName = k
        if (string.find(setName, "ammo_loader")) then
            -- local shortenedName = setName
            -- for short, long in pairs(protoNames.settings) do
            --     if (type(long) == "string") and (long == setName) then
            --         shortenedName = short
            --         break
            --     end
            -- end
            gSets.refs[k] = v.value
        end
    end
end

function gSets.get(setting) return gSets.cache()[setting] end

function gSets.useTech()
    local val = storage["settings_cache"][protoNames.settings.bypassResearch]
    if (val) then return false end
    return true
end

function gSets.ticksPerCycle()
    -- return storage["settings_cache"]["ammo_loader_ticks_between_cycles"]
    return 2
end

gSets.ticksBetweenCycles = gSets.ticksPerCycle

function gSets.slotsPerCycle()
    -- return storage["settings_cache"]["ammo_loader_max_inventories_per_cycle"]
    return 5
    -- return gSets.maxSlotsPerChestTick()
end

gSets.chestsPerCycle = 1

function gSets.maxSlotsPerChestTick() return 5 end

-- function gSets.maxReturnSlots() return 10 end

gSets.maxReturnSlots = 10

function gSets.doArtillery() return storage["settings_cache"]["ammo_loader_fill_artillery"] end

function gSets.doBurners() return storage["settings_cache"]["ammo_loader_fill_burner_structures"] end

function gSets.doTrains() return storage["settings_cache"]["ammo_loader_fill_locomotives"] end

function gSets.enabled() return storage["settings_cache"]["ammo_loader_enabled"] end

function gSets.drawRange(player) return settings.get_player_settings(player)["ammo_loader_draw_range"].value end

function gSets.debugging()
    if (not storage) or (not storage.settings_cache) or (not storage.settings_cache.ammo_loader_debugging) then
        return false
    end
    if (storage["settings_cache"]["ammo_loader_debugging"] == "debugging") then return true end
    return false
end

gSets.debug = gSets.debugging

function gSets.debugImportant()
    if (not storage) or (not storage.settings_cache) or (not storage.settings_cache.ammo_loader_debugging) then
        return false
    end
    if (storage["settings_cache"]["ammo_loader_debugging"] ~= "off") then return true end
    return false
end

function gSets.ticksBetweenChestCache()
    return 30
    -- return storage["settings_cache"]["enabled"]
end

function gSets.ticksBeforeCacheRemoval() return 60 end

gSets.ticksChestCacheDelay = gSets.ticksBeforeCacheRemoval

gSets.entsCheckedPerCycle = 50
-- function gSets.entsCheckedPerCycle()
-- return storage["settings_cache"]["ammo_loader_new_invs_checked_per_cycle"]
-- return 50
-- end

function gSets.chestRadius() return storage["settings_cache"]["ammo_loader_chest_radius"] end

function gSets.rangeIsInfinite()
    if (gSets.chestRadius() <= 0) then return true end
    return false
end

function gSets.slotMax() return storage["settings_cache"]["ammo_loader_max_items_per_slot"] end

function gSets.slotProvideInterval() return 60 end

-- function gSets.maxProvideSlots()
--     return 3
--     -- return gSets.slotsPerCycle()
-- end

function gSets.doReturn() return storage["settings_cache"]["ammo_loader_return_items"] end

function gSets.doUpgrade() return storage["settings_cache"]["ammo_loader_upgrade_ammo"] end

function gSets.maxIndicatorsPerTick() return 10 end

function gSets.maxIndicators() return 10000 end

function gSets.tick(new)
    if not new then
        local tick = storage["settings_cache"]["tick"] or game.tick
        return tick
    end
    storage["settings_cache"]["tick"] = new
end

function gSets.drawReady()
    local interval = 25
    local last = storage["lastDrawTick"] or 0
    local tick = gSets.tick()
    if (tick < last + interval) then return false end
    storage["lastDrawTick"] = tick
    return true
end

function gSets.hasIndicators(val)
    if not val then return storage["hasIndicators"] end
    storage["hasIndicators"] = val
end

function gSets.drawToggle(player, val)
    local isOn = storage["draw_toggle"][player.index] or false
    if (val == nil) then
        return isOn
    elseif (val == false) then
        storage["draw_toggle"][player.index] = nil
    else
        storage["draw_toggle"][player.index] = val
    end
    storage.draw_toggle.count = 0
    for ind, t in pairs(storage.draw_toggle) do storage.draw_toggle.count = storage.draw_toggle.count + 1 end
end

function gSets.checkAfterResearch() return storage["settings_cache"]["ammo_loader_check_after_research"] end

function gSets.slotProvideMinTicks() return 30 end

function gSets.orphansPerCycle() return 10 end

function gSets.itemInfoGUIName() return "ammoLoaderItemInfo" end

---Disabled for now. Always returns false
function gSets.useCartridges()
    -- settings.startup[protoNames.settings.useCartridges].value
    return false
end

function gSets.inserterNextPurgeTick(newVal)
    if (newVal) then
        storage.gSets.inserterNextPurgeTick = newVal
    else
        return storage.gSets.inserterNextPurgeTick or 0
    end
end

function gSets.performanceModeEnabled()
    return true
    -- return gSets.cache()["ammo_loader_performance_mode"]
end

-- function gSets.canUseProfiler()
--     if (storage["profilerEnabled"]) then
--         return true
--     end
--     return false
-- end
gSets._canUseProfiler = false

gSets.ticksBetweenInserterPurge = 18000
gSets.maxSlotsCheckProvPerTick = 40
gSets.maxRendersPerTick = 100
gSets.chestRmSlotsCheckedPerTick = 40
-- gSets.maxProvideSlots = 2
-- gSets.extenderConnectionRange = 30
gSets.extenderSupplyRadius = 4

function gSets.chestRadiusStartup()
    local set = settings.startup.ammo_loader_chest_radius_startup
    if (not set) then return 0 end
    return set.value
end

function gSets.itemFillSize()
    -- return settings.global[protoNames.settings.itemFillSize].value
    return storage.settings_cache[protoNames.settings.itemFillSize]
end

function gSets.maxProvideSlots()
    -- return settings.global[protoNames.settings.providedSlotsPerTick].value
    return storage["settings_cache"][protoNames.settings.providedSlotsPerTick]
end

function gSets.maxSlotsUnsetProvPerTick() return 25 end

function gSets.maxSlotsCheckBestPerTick() return 10 end

function gSets.maxRetrieverChestsPerTick() return 1 end

function gSets.maxTargetsPerRetrieverTick() return 3 end

function gSets.highlightSlots(player)
    return settings.get_player_settings(player)[protoNames.settings.highlightSlots].value
end

function gSets.jetpackModActive()
    if (script.active_mods['jetpack']) then return true end
    return false
end

function gSets.ignoreLogisticTurrets()
    return settings.global[protoNames.settings.ignoreLogisticTurrets].value
end

-- gSets._init()
return gSets
