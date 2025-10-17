Handlers = {}

---@class eventFuncInfo
---@field func fun(event:table)
---@field filters table

---@alias eventName string

Handlers.eventFuncs = {} ---@type table<eventName, eventFuncInfo[]>
Handlers.eventsIgnoreEnabled = {
    on_runtime_mod_setting_changed = true,
    on_load = true,
    on_configuration_changed = true,
    on_init = true,
    on_tick = true
}
Handlers.eventsIgnoreEnabled[protoNames.keys.toggleEnabled] = true

Handlers.eventsUsingFilters = {
    on_built_entity = true,
    on_robot_built_entity = true,
    script_raised_built = true,
    script_raised_revive = true,
    on_entity_cloned = true,
    on_player_mined_entity = true,
    on_robot_mined_entity = true,
    on_entity_died = true,
    script_raised_destroy = true
}

-- function Handlers._init()
--     if (script.active_mods['jetpack']) then
--         onEvents(Handlers.jetpackCharacterRemoved, {
--             "script_raised_destroy", "on_pre_player_died",
--             "on_pre_player_removed", "on_pre_player_left_game"
--         })
--     end
--     for eventName, t in pairs(Handlers.eventsUsingFilters) do
--         local funcInfoList = Handlers.eventFuncs[eventName]
--         for ind, funcInfo in pairs(funcInfoList) do
--             if (funcInfo.)
--         end
--     end
--     onEvents(Handlers.onBuiltAddToQ, {
--         "on_built_entity", "on_robot_built_entity", "script_raised_built", "script_raised_revive", "on_entity_cloned"
--     }, EntDB.entNamesFiltersWithChests())
--     onEvents(Handlers.onRemoved, {
--         "on_player_mined_entity", "on_robot_mined_entity", "on_entity_died", "script_raised_destroy"
--     }, EntDB.entNamesFiltersWithChests())
-- end
-- Init.registerInitFunc(Handlers._init)

function Handlers.enabled(event)
    local didUpdate = false
    if (version.needUpdate()) then
        version.update()
        return false
    end
    if (event) and (event.name) then
        -- cInform('event name: ', util.eventName(event))
        if (Handlers.eventsIgnoreEnabled[util.eventName(event)]) then
            return true
        end
    end
    if (gSets.enabled()) then return true end
    return false
end

-- -@param eventName string
-- function Handlers.eventIgnoresEnabled(eventName)
--     if (not eventName) then return false end
--     if (eventName:match("(ammo%-loader%-key)")) then return true end
--     local allowed = {
--         on_runtime_mod_setting_changed = true,
--         on_load = true,
--         on_configuration_changed = true,
--         on_init = true,
--         on_tick = true
--     }
--     if (allowed[eventName]) then return true end
--     return false
-- end

function Handlers.callEventFuncs(e)
    if (not Handlers.enabled(e)) then return end
    local eName = util.eventName(e)
    if (not eName) or (not Handlers.eventFuncs[eName]) then return end
    local funcInfoList = Handlers.eventFuncs[eName]
    for i = 1, #funcInfoList do
        local funcInfo = funcInfoList[i]
        funcInfo.func(e)
    end
end

function Handlers.onEvents(func, eventNames, filters, ignoreEnabled)
    -- local hand = handler(func)
    for i = 1, #eventNames do
        local name = eventNames[i]
        -- serpLog("event name: ", name)
        local funcList = Handlers.eventFuncs[name]
        if (not funcList) then
            Handlers.eventFuncs[name] = {}
            funcList = Handlers.eventFuncs[name]
            local eventID = defines.events[name]
            if (eventID) then
                script.on_event(eventID, Handlers.callEventFuncs)
            else
                -- serpLog("unknown event name: ", name)
                script.on_event(name, Handlers.callEventFuncs)
            end
        end
        -- script.on_event(event, newFunc)
        ---@type eventFuncInfo
        local funcInfo = {
            func = func,
            filters = filters
        }
        table.insert(funcList, funcInfo)
    end
end

onEvents = Handlers.onEvents

function Handlers.onBuilt(e)
    cInform("createdQ onBuilt")
    local ent = e.entity or e.created_entity or e.destination
    if (not isValid(ent)) then
        local player = util.eventPlayer(e)
        if (isValid(player) and (isValid(player.character))) then
            if (e.name == defines.events.on_pre_build) then
                cInform("onBuilt pre build")
                local cursorStack = player.cursor_stack
                if (cursorStack.valid_for_read) then
                    local itemProto = cursorStack.prototype
                    if ((itemProto) and (itemProto.place_result) and (createdQ.waitQTriggers[itemProto.place_result.name])) then
                        cInform("built ent is waitQ trigger")
                        if (not storage.needCheckWaitQ) then storage.needCheckWaitQ = {} end
                        storage.needCheckWaitQ[player.surface.name] = game.tick + 2
                        cInform(storage.needCheckWaitQ)
                    end
                end
                return
            end
            ent = player.character
        else
            return
        end
    end
    local entName = ent.name
    cInform("entName: ", entName)
    if (entName == HI.protoName) then
        -- ent.destroy {raise_destroy = true}
        return
    end
    local waitEnt = createdQ.waitQTriggers[entName]
    if (waitEnt) then
        cInform("adding to waitQ")
        createdQ.waitQAdd(waitEnt)
        return
    end
    if (e.tags) then
        cInform("createdQ event has tags\n", e.tags)
        createdQ.tick(ent, e.tags)
        return
    end
    if (SL.entIsTrackable(ent)) or (TC.isChestName(entName)) then
        cInform("adding to createdQ")
        createdQ.push(ent)
    end
end

onEvents(Handlers.onBuilt, {
    "on_built_entity", "on_robot_built_entity", "script_raised_built", "script_raised_revive", "on_entity_cloned",
    "on_player_created", "on_player_respawned",
    "on_player_joined_game", "on_pre_build"
})

---Handles all entity removal type events
---@param event EventData.on_pre_player_mined_item
function Handlers.onRemoved(event)
    ---@type LuaEntity
    local ent = event.entity
    local player = util.eventPlayer(event)
    cInform('onRemoved')
    -- if (not player) then return end
    if (not isValid(ent)) then
        if (isValid(player)) and (isValid(player.character)) then
            ent = player.character
        else
            return
        end
    end
    local forceName = ent.force.name
    local cause = event.cause
    -- if (forceName ~= player.force.name) then return end
    if (TC.isChestName(ent.name)) then
        cInform('rm isChestName')
        local chest = TC.getChestFromEnt(ent) ---@type Chest
        if (chest) then
            cInform('destroying chest with id: ', chest.id)
            chest:destroy()
        end
        return
    end
    if SL.entIsTrackable(ent) then
        local slots = SL.getSlotsFromEnt(ent)
        for ind, slot in pairs(slots) do
            local retBool = slot:force():doReturn()
            if (retBool) and (not cause) then
                cInform("try to return for destroy...")
                slot:returnItems()
            end
            cInform("destroy slot")
            slot:destroy()
        end
        local hiEnts = ent.surface.find_entities_filtered { position = ent.position, radius = 0.5, name = HI.protoName }
        for i, hiEnt in pairs(hiEnts) do
            hiEnt.destroy { raise_destroy = false }
        end
        -- local entPos = ent.position
        -- for slot in SL.slotIter() do
        --     if (slot.ent == ent) then
        --         local retBool = slot:force():doReturn()
        --         if (retBool) and (not cause) then
        --             cInform("try to return for destroy...")
        --             slot:returnItems()
        --         end
        --         inform("destroy slot")
        --         slot:destroy()
        --     end
        -- end
    end
end

onEvents(Handlers.onRemoved, {
    "on_pre_player_mined_item", "on_robot_pre_mined", "on_entity_died", "script_raised_destroy", "on_pre_player_died",
    "on_pre_player_removed", "on_pre_player_left_game"
})

function Handlers.playerGunChanged(event)
    -- cInform("player gun changed")
    local player = util.eventPlayer(event)
    if (not isValid(player)) or (not isValid(player.character)) then return end
    local char = player.character
    local charGuns = char.get_inventory(defines.inventory.character_guns)
    local charAmmo = char.get_inventory(defines.inventory.character_ammo)
    local force = Force.get(char.force.name)
    local slots = SL.getSlotsFromEntQ(char)
    for slot in slots:slotIter() do
        local curGun = ""
        local slotInd = slot:slotInd()
        if (isValid(charGuns)) then
            local gunSlot = charGuns[slotInd]
            if (not util.stackIsEmpty(gunSlot)) then
                cInform(gunSlot.name)
                curGun = gunSlot.name
                local proto = prototypes.item[curGun]
                if (proto) then
                    local param = proto.attack_parameters
                    if (param) then
                        if (param.ammo_type) then
                            -- if (param.ammo_type.category) then
                            --     local cat = param.ammo_type.category
                            --     slot:setCategory(param.ammo_type.category)
                            --     slot:queueUrgentProvCheck()
                            --     -- slot:enable()
                            -- end
                            -- elseif (param.ammo_category) then
                            --     slot:setCategory(param.ammo_category.name)
                            --     slot:queueUrgentProvCheck()
                            --     -- slot:enable()
                        elseif (param.ammo_categories) then
                            slot:setCategories(param.ammo_categories)
                            slot:queueUrgentProvCheck()
                            -- slot:enable()
                        else
                            cInform('gun attack parameters no ammo_type')
                            slot:setProv()
                            slot:setCategory()
                        end
                    else
                        cInform('gun no attack parameters')
                    end
                else
                    cInform('gun prototype invalid')
                end
            else --no gun in slot
                cInform('no gun in slot')
                -- slot:destroy()
                -- SL.new(char, defines.inventory.character_ammo, slot)
                slot:setProv()
                slot:setCategory()
                -- slot:disable()
            end
        else
            cInform('char guns does not exist')
            -- slot:destroy()
        end
    end
end

onEvents(Handlers.playerGunChanged, { "on_player_gun_inventory_changed" }) -- on_player_ammo_inventory_changed

function Handlers.settingChange(event)
    if (gSets.requireUpdate[event.setting]) then
        -- if (event.setting == protoNames.settings.enabled) and (settings.global[protoNames.settings.enabled].value == true) then
        -- version.update(false)
        -- else
        version.update()
        -- end
    elseif (event.setting:find("ammo_loader")) then
        util.clearRenders()
        -- version.update()
        gSets.update()
        for slot in SL.iterDB() do
            slot:checkEnabled()
            local insEnt = slot:inserterEnt()
            -- if (insEnt) then insEnt.inserter_stack_size_override = gSets.itemFillSize() end
        end
    end
end

-- function Handlers.settingChange_CrossSurfaces(event)

-- end

onEvents(Handlers.settingChange, { "on_runtime_mod_setting_changed" })

function Handlers.preTick(event)
    gSets.tick(event.tick)
    if (not Handlers.enabled()) then return false end
    if (storage.ItemDB.needTrans) then ItemDB.queueTranslationRequest() end
    return true
end

-- function Handlers.onNthTick(event) if not Handlers.preTick(event) then return end end
function Handlers.onEveryTick(event)
    if not Handlers.preTick(event) then
        cInform('failed pre tick')
        return
    end

    --* schedule version.update for a few ticks after research complete for compatibility with mods that might replace entities after my handler is called
    if (storage.onResearchTick) and (storage.onResearchTick <= event.tick) then
        storage.onResearchTick = nil
        cInform('on research tick: version update')
        version.update()
        return
    end
    -- Handlers.checkOnResearchScheduled()

    createdQ.tick()
    if (createdQ.size() <= 0) then
        Force.tickAll()
        alGui.renderTick()
    end
end

script.on_event(defines.events.on_tick, Handlers.onEveryTick)

function Handlers.jetpackCharacterRemoved(player)
    if (isValid(player)) and (isValid(player.character)) then
        SL.trackAllSlots(player.character)
    end
end

function Handlers.updateRenders(event)
    if not Handlers.preTick(event) then return end
    if (storage.draw_toggle.count > 0) then
        for pIndex, t in pairs(storage.draw_toggle) do
            if (pIndex ~= "count") then
                Handlers.keyChestRangeToggle({
                    player_index = pIndex
                })
                Handlers.keyChestRangeToggle({
                    player_index = pIndex
                })
            end
        end
    end
end

script.on_nth_tick(30, Handlers.updateRenders)
script.on_configuration_changed(version.update)

---@param e EventData
function Handlers.onInit(e)
    Handlers.setupRemoteInterfaces(e)
    Init.doInit()
end

script.on_init(Handlers.onInit)

---@param e EventData
function Handlers.onLoad(e)
    Handlers.setupRemoteInterfaces(e)
    if not version.needUpdate() then Init.doOnLoad() end
end

script.on_load(Handlers.onLoad)

---Setup events for remote interfaces in on_init/on_load
---@param e EventData
function Handlers.setupRemoteInterfaces(e)
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), Handlers.pickerMovedEnt)
    end
end

---Handler for the Picker Dollies mod entity move event
function Handlers.pickerMovedEnt(e)
    if (not Handlers.enabled()) then return end
    cInform("picker moved ent")
    local player = util.eventPlayer(e) ---@type LuaPlayer
    local ent = e.moved_entity ---@type LuaEntity
    local startPos = e.start_pos ---@type Position
    cInform(startPos)
    if (not isValid(player)) or (not isValid(ent)) or (not startPos) or (not SL.entIsTrackable(ent)) or
        (SL.entNeedsProvided(ent)) then
        if (gSets.debug()) then
            cInform("exit picker moved event: ", player, " || ", ent, " || ", startPos, " || ", SL.entIsTrackable(ent),
                " || ", SL.entNeedsProvided(ent))
        end
        return
    end
    local slotsQ = SL.getSlotsFromEntQ(ent)
    if (slotsQ:size() <= 0) then
        cInform("picker ent has no tracked slots.")
        return
    end
    for slot in slotsQ:slotIter() do
        local ins = slot:inserterEnt()
        if (isValid(ins)) then
            local newDropPos = slot:boundingBoxCenter()
            cInform("start: ", startPos, " || new: ", newDropPos)
            ins.drop_position = slot:boundingBoxCenter()
            local newIns = HI.new(slot) ---@type LuaEntity
            local oldHeld = ins.held_stack
            local newHeld = newIns.held_stack
            newIns.set_filter(1, ins.get_filter(1))
            newIns.pickup_position = ins.pickup_position
            if (not util.stackIsEmpty(newHeld)) and (not util.stackIsEmpty(oldHeld)) then
                local oldHeldStack = {
                    name = oldHeld.name,
                    count = oldHeld.count
                }
                local newHeldStack = {
                    name = newHeld.name,
                    count = newHeld.count
                }
                cInform(serpent.block(oldHeldStack), " || ", serpent.block(newHeldStack))
                newHeld.transfer_stack(oldHeld)
            end
            ins.destroy()
            slot._inserterEnt = newIns
        else
            cInform("inserter ent invalid")
        end
    end
end

-- function Handlers.checkOnResearchScheduled()
--     if (storage.onResearchTick) and (storage.onResearchTick <= game.tick) then
--         storage.onResearchTick = nil
--         version.update()
--     end
-- end

function Handlers.onResearch(event)
    -- if not Handlers.enabled() then return end
    local tech = event.research
    local techName = event.research.name
    if (Map.containsValue(protoNames.tech, tech.name)) then
        version.update()
    elseif (gSets.checkAfterResearch()) then
        storage.onResearchTick = event.tick + 2
        -- version.update()

        --* if certain mods are active, check entities regardless of setting
    elseif (script.active_mods["EndgameCombat"] or script.active_mods["EndgameCombatRampantPatch"]) then
        storage.onResearchTick = event.tick + 2
    end
end

onEvents(Handlers.onResearch, { "on_research_finished" })

function Handlers.keyReturn(event)
    inform("returning all items.")
    local player = game.players[event.player_index]
    if (player) then for slot in Force.get(player.force.name):iterSlots() do slot:returnItems() end end
end

onEvents(Handlers.keyReturn, { protoNames.keys.returnItems })

function Handlers.keyReset() version.update() end

onEvents(Handlers.keyReset, { protoNames.keys.resetMod })

function Handlers.keyToggleEnabled()
    local isEnabled = gSets.enabled()
    if isEnabled then
        settings.global["ammo_loader_enabled"] = {
            value = false
        }
        -- version.update()
        ctInform("Ammo Loader Mod disabled")
    else
        settings.global["ammo_loader_enabled"] = {
            value = true
        }
        -- version.update()
        ctInform("Ammo Loader Mod enabled")
    end
end

script.on_event("ammo-loader-key-toggle-enabled", Handlers.keyToggleEnabled)
-- onEvents(Handlers.keyToggleEnabled, {protoNames.keys.toggleEnabled})

function Handlers.keyChestRangeToggle(event)
    local pInd = event.player_index
    local player = game.players[pInd]
    if (not player) then return nil end
    util.clearPlayerRenders(player)
    local isOn = gSets.drawToggle(player)
    if (isOn) then
        gSets.drawToggle(player, false)
        return
    end
    local chests = Force.get(player.force.name).chests
    for chest in chests:chestIter() do
        chest:drawRange(player)
        chest:highlightConsumers(player)
    end
    gSets.drawToggle(player, true)
end

onEvents(Handlers.keyChestRangeToggle, { protoNames.keys.toggleChestRange })

function Handlers.keyManualScan(event)
    local player = game.players[event.player_index]
    if not player then return end
    
    ctInform("Manual scan initiated by ", player.name)
    
    -- Check if currently on a surface
    local currentSurface = player.surface
    if currentSurface and currentSurface.valid then
        -- Scan current surface
        ctInform("Scanning current surface: ", currentSurface.name)
        createdQ.checkSurfaceEntities(currentSurface)
        
        -- Also offer to scan all surfaces if player holds SHIFT
        if event.shift then
            ctInform("Scanning all surfaces...")
            version.update()
        end
    end
end

onEvents(Handlers.keyManualScan, { protoNames.keys.manualScan })

function Handlers.onPlayerSelectionChangedClearRenders(e)
    local player = util.eventPlayer(e)
    if (not player) then return end

    local selected = player.selected
    if (isValid(e.last_entity)) then
        if (SL.entIsTrackable(e.last_entity) or TC.isChest(e.last_entity)) then
            rendering.clear("ammo-loader")
        end
    end
    if (isValid(selected)) then
        local isChest = Handlers.onPlayerSelectionChangedRenderChest(e)
        if (not isChest) then
            Handlers.onPlayerSelectionChangedRenderSlot(e)
        end
    end
end

onEvents(Handlers.onPlayerSelectionChangedClearRenders, { "on_selected_entity_changed" })

function Handlers.onPlayerSelectionChangedRenderChest(e)
    local player = util.eventPlayer(e)
    if (not player) then return end
    rendering.clear("ammo-loader")
    local selected = player.selected
    if (isValid(selected)) and (TC.isChestName(selected.name)) then
        local chest = TC.getChestFromEnt(selected) ---@type Chest
        if (chest) then
            ---debug info about chest
            serpLog("force provCats:\n", chest:force().provCats)

            if (gSets.highlightSlots(player)) then
                chest:highlightConsumers(player)
            end
            if (gSets.drawRange(player)) then
                chest:drawRange(player)
            end
            return true
        end
    end
end

-- onEvents(Handlers.onPlayerSelectionChangedRenderChest, {"on_selected_entity_changed"})

function Handlers.onPlayerSelectionChangedRenderSlot(e)
    local player = util.eventPlayer(e)
    if (not player) then return false end
    if (not gSets.highlightSlots(player)) then return false end
    local slots = {}
    local selected = player.selected
    if (isValid(e.last_entity)) then
        slots = SL.getSlotsFromEnt(e.last_entity) ---@type table<number, Slot>
        if (not table.isEmpty(slots)) then rendering.clear("ammo-loader") end
    end
    if (not isValid(selected)) then return false end
    slots = SL.getSlotsFromEnt(selected) ---@type table<number, Slot>
    if (#slots <= 0) then return false end
    local isHighlighted = false
    ---@param slot Slot
    for i, slot in pairs(slots) do
        cInform("slotID: " .. serpent.block(slot.id))
        cInform("slotCat: " .. serpent.block(slot:categories()))
        cInform("slotInserterFilter: " .. serpent.block(slot:filterItem()))
        if (slot:sourceID()) then
            if (not isHighlighted) then
                SL.highlightEnt(selected, player)
                isHighlighted = true
            end
            slot:drawLineToProvider(player)
            return true
        end
    end
    -- for ind, slot in pairs(slots) do
    -- end
    return false
end

-- onEvents(Handlers.onPlayerSelectionChangedRenderSlot, {"on_selected_entity_changed"})

function Handlers.onEntitySettingsPasted(e)
    -- playerIndex, source, destination, name, tick
    -- if (not TC.isChest(source)) or (not TC.isChest(destination)) then return end
    cInform("entity settings pasted")
    local sourceChest = TC.getChestFromEnt(e.source)
    local destChest = TC.getChestFromEnt(e.destination)
    if (sourceChest) and (destChest) then
        destChest:setEntFilter(sourceChest._entFilter, sourceChest._entFilterMode)
        return
    end

    if (SL.entIsTrackable(e.source)) and (SL.entIsTrackable(e.destination)) then
        local sourceSlots = SL.getSlotsFromEnt(e.source)
        local destSlots = SL.getSlotsFromEnt(e.destination)
        if (not table.isEmpty(sourceSlots)) and (not table.isEmpty(destSlots)) then
            local sourceFilter = sourceSlots[1]._ammoFilter
            local sourceFilterMode = sourceSlots[1]._ammoFilterMode
            for i, destSlot in pairs(destSlots) do
                destSlot:setAmmoFilter(sourceFilter, sourceFilterMode)
            end
            return
        end
    end
end

onEvents(Handlers.onEntitySettingsPasted, { "on_entity_settings_pasted" })

local function save_blueprint_data(blueprint, mapping)
    if (not blueprint) or (not blueprint.valid_for_read) or (blueprint.get_blueprint_entity_count() ~= #mapping) then
        return
    end
    for i, entity in pairs(mapping) do
        if entity.valid then
            local filters = nil
            local filterMode = nil

            local slots = SL.getSlotsFromEnt(entity)
            if (not table.isEmpty(slots)) then
                filters = slots[1]._ammoFilter
                filterMode = slots[1]._ammoFilterMode
                if filters then
                    blueprint.set_blueprint_entity_tag(i, SL.tags.itemFilters, filters)
                    blueprint.set_blueprint_entity_tag(i, SL.tags.filterMode, filterMode)
                end
            end

            local chest = TC.getChestFromEnt(entity)
            if (chest) then
                filters = chest._entFilter
                filterMode = chest._entFilterMode
                if (filters) then
                    blueprint.set_blueprint_entity_tag(i, TC.tags.entFilters, filters)
                    blueprint.set_blueprint_entity_tag(i, TC.tags.filterMode, filterMode)
                end
            end
        end
    end
end

-- saving to copy-paste tool & cut-paste tool
function Handlers.onPlayerSetupBlueprint(event)
    local player = game.players[event.player_index]

    local cursor = player.cursor_stack
    if cursor and cursor.valid_for_read and cursor.type == 'blueprint' then
        save_blueprint_data(cursor, event.mapping.get())
    else
        storage.blueprintMappings[player.index] = event.mapping.get()
    end
end

Handlers.onEvents(Handlers.onPlayerSetupBlueprint, { "on_player_setup_blueprint" })

-- saving to regular blueprint
function Handlers.onPlayerConfiguredBlueprint(event)
    local player = game.players[event.player_index]
    local mapping = storage.blueprintMappings[player.index]
    local cursor = player.cursor_stack

    if cursor and cursor.valid_for_read and cursor.type == 'blueprint' and mapping and #mapping == cursor.get_blueprint_entity_count() then
        save_blueprint_data(cursor, mapping)
    end
    storage.blueprintMappings[player.index] = nil
end

Handlers.onEvents(Handlers.onPlayerConfiguredBlueprint, { "on_player_configured_blueprint" })
