---Chests represent a single Loader Chest in-game.
---@class Chest : dbObject
TC = {}

TC.modes = {
    retriever = "retriever",
    provider = "provider"
}
TC.modes['storage'] = "storage"

TC.tags = {
    entFilters = "amlo_chest_ent_filters",
    filterMode = "amlo_chest_filter_mode"
}

-- ---@class ChestConsumerLineRenders
-- TC.consLineRends = {
--     ---@param chest Chest
--     getChestRends = function(chest)
--         if (not chest) then return {} end
--         return chest._consRenderLines
--     end,
--     ---@param chest Chest
--     ---@param slot Slot
--     getSlotRends = function(chest, slot)
--         if (not chest) or (not slot) then return {} end
--         local chestRends = TC.consLineRends.getChestRends(chest)
--         local slotRends = chestRends[slot.id]
--         if (not slotRends) then
--             slotRends = {}
--             chestRends[slot.id] = slotRends
--         end
--         return slotRends
--     end,
--     ---@param chest Chest
--     ---@param slot Slot
--     ---@param player LuaPlayer
--     getSlotPlayerRend = function(chest, slot, player)
--         if (not chest) or (not slot) or (not isValid(player)) then return {} end
--         local slotRends = TC.consLineRends.getSlotRends(slot)
--         local playerRend = slotRends[player.index]
--         if (not playerRend) then
--             playerRend = slot:drawLineToProvider(player)
--             slotRends[player.index] = playerRend
--         end
--         return playerRend
--     end,
--     ---@param player LuaPlayer
--     iterPlayerRends = function(player)
--         if (not isValid(player)) then return end
--         local chestIter = Force.get(player.force.name):iterChests()
--         local rends = TC.consLineRends.getChestRends(chestIter())
--         local rendsIter = util.pairsIter(rends)
--         local fun
--         fun = function()
--             local slotID, pRend = rendsIter()
--             if (not slotID) or (not pRend) then
--                 local chest = chestIter()
--                 if (not chest) then return end
--                 rendsIter = util.pairsIter(TC.consLineRends.getChestRends(chest))
--                 return fun()
--             elseif (pRend[player.index]) then
--                 return pRend[player.index], pRend
--             end
--             return fun()
--         end
--         return fun
--     end,
--     ---@param player LuaPlayer
--     destroyAllPlayerRends = function(player)
--         if (not isValid(player)) then return end
--         for rendID, tbl in TC.consLineRends.iterPlayerRends(player) do
--             rendering.destroy(rendID)
--             tbl[player.index] = nil
--         end
--     end
-- }
-- TC.consLineRends.objMT = {
--     __metatable = TC.consLineRends
-- }

-- ---@return ChestConsumerLineRenders
-- TC.consLineRends.new = function() return setmetatable({}, TC.consLineRends.objMT) end

-- TC.areaRends = {
--     ---@param player LuaPlayer
--     destroyAllPlayerRends = function(player)
--         if (not isValid(player)) then return end
--         for rendID, chest in TC.areaRends.iterAreaRends(Force.get(player.force.name)) do
--             if (util.renderHasPlayer(rendID, player)) then
--                 rendering.destroy(rendID)
--                 chest._areaRenderID = nil
--             end
--         end
--     end,
--     ---@param force Force
--     iterAreaRends = function(force)
--         local cIter = force:iterChests()
--         local fun
--         ---@return renderID, Chest
--         fun = function()
--             local chest = cIter()
--             if (not chest) then return end
--             if (chest._areaRenderID) then return chest._areaRenderID, chest end
--             return fun()
--         end
--         return fun
--     end
-- }

---@class ConsumerLineRenderInfo
---@field slotID number
---@field renderID number
---@field playerID number
---@field chestID number

TC.className = "TrackedChest"
TC.dbName = TC.className
DB.register(TC.dbName)
TC.objMT = {
    __index = TC
}

function TC._init()
    storage["TC"] = {}
end

Init.registerFunc(TC._init)

function TC._preInit()
    if (not storage.DB) then return end
    -- storage.persist.chestFilters = nil
    local chestFilters = {}
    local chestsWithFilters = 0
    ---@param chest Chest
    for chest in DB.iter(TC.dbName) do
        if (chest) then
            local newFilterInfo = {
                ent = chest.ent,
                -- inv = chest:inv(),
                -- pos = chest.ent.position,
                -- surfaceName = chest.ent.surface.name,
                -- entName = chest.ent.name,
                -- forceName = chest.ent.force.name,
                -- inv = chest:inv(),
                filters = chest._entFilter,
                filterMode = chest._entFilterMode
            }
            table.insert(chestFilters, newFilterInfo)
        end
        if (chest) and (chest.ent) and (chest.ent.valid) and (chest._entFilter) then
            chestsWithFilters = chestsWithFilters + 1
            -- serpLog("chest.ent: " .. chest.ent.name .. " ", chest.ent.position)
        end
    end
    -- serpLog("chests with filters: " .. chestsWithFilters)
    storage.persist.chestFilters = chestFilters
    -- serpLog("chestFilters:\n", storage.persist.chestFilters)
end

Init.registerPreInitFunc(TC._preInit)

function TC._onLoad()
    ---@param obj Chest
    for id, obj in pairs(DB.getEntries(TC.dbName)) do
        setmetatable(obj, TC.objMT)
        setmetatable(obj._consumerQ, idQ.objMT)
        setmetatable(obj._retrieverTargets, EntQ.objMT)
        setmetatable(obj._retrieverTargetsMoving, EntQ.objMT)
    end
end

Init.registerOnLoadFunc(TC._onLoad)

function TC.master() return storage["TC"] end

function TC.chestNames(listType)
    if not listType then return TC.master()["chestNames"] end
    return TC.master()["chestNames"][listType]
end

function TC.chestDB() return DB.getEntries(TC.dbName) end

---@param ent LuaEntity
function TC.isTrackable(ent)
    if (not isValid(ent)) or (not TC.isChestName(ent.name)) then return false end
    return true
end

function TC.isChest(ent)
    if (not isValid(ent)) then return false end
    return Map.containsValue(protoNames.chests, ent.name)
end

function TC.isChestName(name)
    if not name then return false end
    if (string.find(name, "ammo.loader.chest")) then return true end
    return false
end

---Get Chest from id.
---@return Chest
function TC.getObj(id)
    if (type(id) == "table") and (id.className) and (id.className == TC.className) then return id end
    return DB.getObj(TC.dbName, id) ---@type Chest
end

---@return Chest | nil
function TC.getChestFromEnt(ent)
    if (not isValid(ent)) or (not TC.isChestName(ent.name)) then
        cInform("ent does not have chest obj")
        return nil
    end
    ---@param obj Chest
    for id, obj in pairs(DB.getEntries(TC.dbName)) do
        if (obj.ent == ent) then
            cInform('getChestFromEnt found chest obj')
            return obj
        end
    end
    cInform('getChestFromEnt return nil')
    return nil
end

---@return alChestMode | nil
function TC.getModeFromEnt(ent)
    if (not TC.isTrackable(ent)) then return end
    if (ent.name == protoNames.chests.storage) then
        return TC.modes.storage
    end
    return TC.modes.provider
end

---Create new TrackedChest object
---@param ent LuaEntity
---@param mode string | nil
---@return Chest | nil
function TC.new(ent, mode)
    if (not TC.isTrackable(ent)) then
        cInform("TC.new: entity not valid chest")
        return nil
    end
    if (not mode) then mode = TC.getModeFromEnt(ent) end

    ---@class Chest : dbObject
    local obj = {}
    setmetatable(obj, TC.objMT)
    obj.ent = ent
    obj._forceName = ent.force.name
    obj._surfaceIndex = ent.surface.index
    obj._position = ent.position
    obj._inv = ent.get_inventory(defines.inventory.chest)
    local pos = ent.position

    if (not gSets.rangeIsInfinite()) then obj._area = Position.expand_to_area(ent.position, gSets.chestRadius()) end
    obj._areaRenderID = nil
    obj.id = DB.insert(TC.dbName, obj)
    obj._consumerQ = idQ.newSlotQ(true)

    local rad = gSets.chestRadius()
    local force = Force.get(ent.force.name)
    obj._provItemCount = 0
    obj._cacheLastTick = 0
    obj._invCache = {} ---@type table<string, int>
    obj._removalCache = {}
    obj._addProvList = {}
    obj._removeProvList = {}
    obj._renderInfo = {} -- ** Has the format [playerIndex] = [slotID=num, count=num]
    ---@alias slotID number
    ---@alias renderID number
    ---@alias chestID number
    ---@alias playerIndex number
    ---@alias ConsLinePlayers table<playerIndex, renderID>
    ---@alias ChestConsLines table<slotID, ConsLinePlayers>
    obj._consRenderLines = {} ---@type ChestConsLines
    obj._consCountRender = nil
    obj._isValid = nil
    obj._validCheckTick = 0
    obj._retrieverTargets = EntQ.new(true)
    obj._hiddenInserters = {} ---@type table<int, LuaEntity>
    obj._retrieverTargetsMoving = EntQ.new(true)
    obj._retrieverTargetInvTypes = {} ---@type table<int, number>
    obj._retrieverTargetInventories = {} ---@type table<int, LuaInventory>
    obj._retrieverInventoryTickCounter = 1
    obj._range = gSets.chestRadius()
    obj._entFilter = {}
    obj._entFilterMode = util.FilterModes.blacklist
    obj._mode = mode

    if (storage.persist.chestFilters) then
        -- serpLog("persist size: ", table_size(storage.persist.chestFilters))
        for i, filterInfo in pairs(storage.persist.chestFilters) do
            -- if (filterInfo.entName == ent.name) and (filterInfo.forceName == ent.force.name) and (filterInfo.surfaceName == ent.surface.name) and (filterInfo.pos.x == ent.position.x) and (filterInfo.pos.y == ent.position.y) then
            if (filterInfo.ent) and (filterInfo.ent == ent) then
                -- serpLog('found previous chest filters')
                obj._entFilter = filterInfo.filters
                obj._entFilterMode = filterInfo.filterMode
                storage.persist.chestFilters[i] = nil
                break
                -- end
            else
                -- serpLog(filterInfo.entName, " <--> ", ent.name)
                -- serpLog(filterInfo.forceName, " <--> ", ent.force.name)
                -- serpLog(filterInfo.surfaceName, " <--> ", ent.surface.name)
                -- serpLog(filterInfo.pos.x, " <--> ", ent.position.x)
                -- serpLog(filterInfo.pos.y, " <--> ", ent.position.y)
            end
        end
    else
        -- serpLog('no global persist chestfilters??')
    end

    if (mode == TC.modes.provider) then
        force:addChest(obj)
    elseif (mode == TC.modes.storage) then
        force:addStorage(obj)
    elseif (mode == TC.modes.retriever) then
        force:addRetriever(obj)
    end

    cInform("created new chest")
    return obj
end

function TC:inv() return self._inv or self.ent.get_inventory(defines.inventory.chest) end

function TC:isStorage()
    if (self.ent.name == protoNames.chests.storage) then return true end
    return false
end

function TC:getItemByRank(catName, rank) return self:force():getItemByRank(catName, rank) end

TC.itemByRank = TC.getItemByRank

function TC:isInRange(slot) return util.isInRange(slot, self) end

function TC:position() return self._position or self.ent.position end

function TC:surface()
    local idx = self._surfaceIndex
    if idx then
        return game.surfaces[idx]
    end
    return self.ent.surface
end

function TC:surfaceIndex() return self._surfaceIndex or self.ent.surface.index end

function TC:surfaceName() return self:surface().name end

---Remove Chest from database to open for garbage collection.
function TC:destroy()
    self._destroying = true
    local force = self:force()
    force:removeProvID(self.id, true)
    force.chests:softRemove(self)
    force.storageChests:softRemove(self)
    -- for slot in force.slots:slotIter() do
    --     if (slot:sourceID() == self.id) then
    --         slot:setProv()
    --         force.slotsNeedCheckBestProv:push(slot)
    --     end
    -- end
    DB.deleteID(TC.dbName, self.id)
end

---Check object validity.
function TC:isValid()
    if (not self) then return false end
    -- local tick = gSets.tick()
    -- local lastCheckTick = self._validCheckTick or 0
    -- if (self._isValid ~= nil) and (lastCheckTick == tick) then
    --     return self._isValid
    -- end
    local ent = self.ent
    if (not ent) or (not ent.valid) then
        -- self._isValid = false
        -- self._validCheckTick = tick
        return false
    end
    -- self._isValid = true
    -- self._validCheckTick = tick
    return true
end

TC.valid = TC.isValid

function TC:drawRange(player)
    if (not isValid(self.ent)) or (not isValid(player)) or (player.surface.name ~= self:surfaceName()) or
        (gSets.rangeIsInfinite()) then
        return
    end
    local rad = gSets.chestRadius()
    local pos = self:position()
    local left_top = {
        x = pos.x - rad,
        y = pos.y - rad
    }
    local right_bottom = {
        x = pos.x + rad,
        y = pos.y + rad
    }
    -- self._areaRenderID =
    -- rendering.draw_circle(
    -- {
    --     -- color = util.colors.fuchsia,
    --     color = {r = 0.05, g = 0.2, b = 0.15, a = 0.05},
    --     radius = rad,
    --     width = 8,
    --     target = self.ent,
    --     filled = true,
    --     -- left_top = self.area.left_top,
    --     -- right_bottom = self.area.right_bottom,
    --     surface = self:surfaceName(),
    --     players = {player},
    --     draw_on_ground = true
    -- }
    local areaRender = rendering.draw_rectangle({
        color = util.colors.chestRangeColor,
        width = 8,
        left_top = left_top,
        right_bottom = right_bottom,
        -- target = self.ent,
        filled = true,
        surface = self:surfaceName(),
        players = { player },
        draw_on_ground = false
    })
    self._areaRenderID = areaRender.id
end

function TC:highlightConsumers(player)
    -- if (gSets.debug()) then
    --     local registry = ProvReg.new(self:force())
    --     -- local registeredCats = ProvReg.provCategories(registry)
    --     local registeredCats = registry:provCategories(self)
    --     -- serpInform(registeredCats)
    -- end

    local playerAddRm = util.renderAddPlayer
    if (not isValid(player)) or (self:surface() ~= player.surface) then return end
    local force = self:force()
    -- local consQ = idQ.newSlotQ(true)
    local slotCount = 0
    local drawLineSlots = idQ.newSlotQ(true)
    for slot in force.slots:slotIter() do
        if (slot:sourceID() == self.id) then
            -- consQ:push()
            slotCount = slotCount + 1
            -- cInform('consumer:\nname: '..slot.ent.name..' | id: '..slot.id..' | slotIndex: '..slot:slotInd())
            if (slot:surface() == self:surface()) then
                drawLineSlots:push(slot)
            end
        end
    end
    local consCountRender = rendering.draw_text({
        text = { "", tostring(slotCount) },
        surface = self:surface(),
        target = self.ent,
        scale = 1.5,
        target_offset = { -0.25, -1.5 },
        color = { 1.0, 1.0, 1.0 },
        players = { player },
        draw_on_ground = false
        -- scale_with_zoom = true
    })
    self._consCountRender = consCountRender.id

    cInform("providing ", slotCount, " slots.")
    if (slotCount > gSets.maxRendersPerTick) then return end
    for slot in drawLineSlots:slotIter(nil, false) do
        local line = slot:drawLineToProvider(player)
        if (line) then slot:highlight(player) end
    end
end

function TC:force() return Force.get(self:forceName()) end

function TC:forceName() return self._forceName or self.ent.force.name end

function TC:itemAmt(item, new)
    if (new) then
        self._invCache[item] = new
        return new
    end
    local amt = self._invCache[item] or 0
    return amt
end

function TC:cacheRemove(item, amt)
    if (amt <= 0) then return end
    local newAmt = self:itemAmt(item) - amt
    return self:itemAmt(item, newAmt)
end

function TC:cacheAdd(item, amt) return self:itemAmt(item, self:itemAmt(item) + amt) end

---Insert items into chest while maintaining inventory cache. Returns the number of items inserted.
---@param stack ItemStack
---@return integer
function TC:insert(stack)
    if (util.stackIsEmpty(stack)) then return 0 end
    local amtInserted = self:inv().insert(stack)
    local cache = self._invCache
    if (amtInserted > 0) then
        local item = stack.name
        if not cache[item] then
            cache[item] = amtInserted
        else
            cache[item] = cache[item] + amtInserted
        end
    end
    return amtInserted
end

---Remove items from the chest inventory while maintaining the inventory cache. Returns the number of items removed.
---@param stack ItemStack
---@return integer
function TC:remove(stack)
    if (util.stackIsEmpty(stack)) then return 0 end
    local cache = self._invCache
    local amtRemoved = self:inv().remove(stack)
    local item = stack.name
    if (cache[item]) then cache[item] = cache[item] - amtRemoved end
    return amtRemoved
end

function TC:itemInfo(itemName) return self:force():itemInfo(itemName) end

---@param itemName string
function TC:isProvidingItem(itemName)
    local inf = self:itemInfo(itemName)
    if (not inf) then return false end
    local force = self:force()
    if (force.provCats[inf.category]) and (force.provCats[inf.category][inf.rank]) and
        (force.provCats[inf.category][inf.rank][self.id]) then
        return true
    end
    return false
end

function TC:catItems(catName)
    local items = {}
    for itemName, count in pairs(self._invCache) do
        local inf = self:itemInfo(itemName)
        if (inf.category == catName) and (count >= inf.fillLimit) then items[itemName] = count end
    end
    return items
end

function TC:updateCache()
    local gTick = game.tick
    local ticksToWait = gSets.ticksBeforeCacheRemoval()
    local minTicks = gSets.ticksBetweenChestCache()
    local fTick = gTick + ticksToWait
    local newCache = self._invCache
    local selfInv = self:inv()
    local oldCache = self._invCache
    local force = self:force()
    local rmCache = self._removalCache
    self._cacheLastTick = self._cacheLastTick or 0
    -- cInform('TC:updateCache-- gTick: ', gTick, ' ', self._cacheLastTick + minTicks)
    if (gTick >= self._cacheLastTick + minTicks) then
        self._cacheLastTick = gTick
        local newContents = selfInv.get_contents()
        newCache = {}
        for j = 1, #newContents do
            newCache[newContents[j].name] = newContents[j].count
        end
        self._invCache = newCache

        for item, count in pairs(newCache) do
            local inf = self:itemInfo(item)
            if (inf) then
                if ((not self:isProvidingItem(item)) or (rmCache[item])) then
                    cInform('register prov')
                    force:registerProv(self, item)
                    rmCache[item] = nil
                end
            end
        end
        for catName, catItems in pairs(force.provCats) do
            for itemRank, itemProvs in pairs(catItems) do
                local itemObj = self:itemByRank(catName, itemRank)
                if (itemObj) then
                    local itemName = itemObj.name
                    local fillLimit = itemObj.fillLimit
                    local itemCount = selfInv.get_item_count(itemName)
                    for provID, curSlotID in pairs(itemProvs) do
                        if (not rmCache[itemName]) and (provID == self.id) and
                            (itemCount == 0 or (itemCount < fillLimit)) then
                            rmCache[itemName] = fTick
                        end
                    end
                end
            end
        end
        for item, tick in pairs(rmCache) do
            if (gTick >= tick) then
                rmCache[item] = nil
                force:removeProv(self.id, item)
            end
        end
    end
end

function TC:tick()
    -- serpLog("TC:tick")
    if (self._mode == TC.modes.storage) then return end
    local gTick = gSets.tick()
    if (self._mode == TC.modes.provider) then
        cInform('is provider')
        self:updateCache()
    elseif (self._mode == TC.modes.retriever) then
        self:tickRetriever()
    end
end

---@param newFilter alEntityFilter
---@param newMode alFilterMode
function TC:setEntFilter(newFilter, newMode)
    if (not newFilter) then newFilter = {} end
    if (not newMode) then newMode = util.FilterModes.blacklist end
    -- newMode = newMode or util.FilterModes.blacklist
    if (not table.equals(newFilter, self._entFilter)) or (self._entFilterMode ~= newMode) then
        self._entFilter = newFilter
        self._entFilterMode = newMode
        self:force():removeProvID(self.id, true)
        self._invCache = {}
    end
end

---Check chest's entity filters to see if a slot will pass
---@param slot Slot
function TC:filterAllows(slot)
    if (not self._entFilter) then return true end
    -- local whitelist = util.FilterModes.whitelist
    -- local blacklist = util.FilterModes.blacklist
    local entName = slot:entName()
    if (self._entFilter[entName]) then
        if (self._entFilterMode == util.FilterModes.whitelist) then
            return true
        elseif (self._entFilterMode == util.FilterModes.blacklist) then
            return false
        end
    else
        if (self._entFilterMode == util.FilterModes.whitelist) then
            return false
        elseif (self._entFilterMode == util.FilterModes.blacklist) then
            return true
        end
    end
end

function TC:filterSlotIsWhitelisted(slot)
    if (not self._entFilter) or (self._entFilterMode and self._entFilterMode == util.FilterModes.blacklist) then return false end
    local entName = slot:entName()
    if (self._entFilter[entName]) then if (self._entFilterMode == util.FilterModes.whitelist) then return true end end
    return false
end

function TC:amtCanReturn(stack)
    if (not stack) or (stack.count <= 0) then return 0 end
    local inv = self:inv()
    local firstStack = inv.find_item_stack(stack.name)
    if (not firstStack) then return 0 end
    local amtCanInsert = inv.get_insertable_count(stack.name)
    if (stack.count < amtCanInsert) then amtCanInsert = stack.count end
    return amtCanInsert
end

function TC:isRemovingProv(itemName)
    local force = self:force()
    if (not force.rmProvs[self.id]) or (not force.rmProvs[self.id][itemName]) then return false end
    return true
end

function TC:switchVal()
    local mode = util.FilterModes.blacklist
    local val = "right"
    if (self._entFilterMode) then mode = self._entFilterMode end
    if (mode == util.FilterModes.whitelist) then val = "left" end
    return val
end

return TC
