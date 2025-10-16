---Slots represent a single slot on any entity that is being provided to.
---@class Slot
---@field _categories Hash<alAmmoCategory, boolean>
---@field _ammoFilter Hash<alAmmoName, boolean>
---@field _ammoFilterMode alFilterMode
SL = {}

SL.typesCanMove = EntDB.typesCanMove
SL.slotWithProviderColor = util.colors.slotWithProviderColor

SL.className = "TrackedSlot"
SL.dbName = SL.className
DB.register(SL.dbName)

SL.objMT = {
    __index = SL
}

SL.tags = {
    itemFilters = "amlo_consumer_item_filters", ---@type SlotFilterTag
    filterMode = "amlo_consumer_filter_mode" ---@type SlotFilterTag
}

local manhatDist = Position.manhattan_distance
local dist = Position.distance

function SL._onLoad() for id, obj in pairs(DB.getEntries(SL.dbName)) do setmetatable(obj, SL.objMT) end end

Init.registerOnLoadFunc(SL._onLoad)

SL.ammoInvTypes = {
    defines.inventory.turret_ammo, defines.inventory.car_ammo, defines.inventory.character_ammo,
    defines.inventory.artillery_turret_ammo, defines.inventory.artillery_wagon_ammo
}

function SL._init()
    storage["SL"] = {}
    storage["SL"]["vars"] = {}
    storage["blueprintMappings"] = {}
    storage["ghostTags"] = {}
    storage.playersNeedCharacterCheck = {}
end

Init.registerFunc(SL._init)

function SL._preInit()
    if (not storage.DB) then return end
    local slotFilters = {}
    local slotsWithFilters = 0
    ---@param slot Slot
    for slot in DB.iter(SL.dbName) do
        if (slot) and (slot.ent) and (slot.ent.valid) and (slot._ammoFilter) then
            slotsWithFilters = slotsWithFilters + 1
            table.insert(slotFilters, {
                ent = slot.ent,
                -- inv = chest:inv(),
                filters = slot._ammoFilter,
                filterMode = slot._ammoFilterMode
            })
            -- serpLog("chest.ent: " .. chest.ent.name .. " ", chest.ent.position)
        end
    end
    -- serpLog("chests with filters: " .. chestsWithFilters)
    storage.persist.slotFilters = slotFilters
    -- serpLog("chestFilters:\n", chestFilters)
end

Init.registerPreInitFunc(SL._preInit)

function SL.vars() return storage.SL.vars end

function SL:setPrevSourceID(id) self._prevSourceID = id end

function SL:prevSourceID() return self._prevSourceID end

function SL:checkProv() return self._checkProv end

function SL:setCheckProv(val) self._checkProv = val end

---@return ItemStack Empty ItemStack (name="", count=0).
function SL.emptyStack()
    return {
        name = "",
        count = 0,
    }
end

---Test an entity to see if it may have trackable inventory slots.
---@param ent LuaEntity
---@return boolean
function SL.entIsTrackable(ent)
    if (not isValid(ent)) or (not SL.entProtoIsTrackable(ent.prototype)) then return false end
    return true
end

---Test an entity prototype to see if an instance of it might have trackable inventory slots.
---@param proto LuaEntityPrototype
---@return boolean
function SL.entProtoIsTrackable(proto)
    if (not proto) or (EntDB.globalBlacklist[proto.name]) then return false end
    -- if (proto.name == HI.protoName) then
    -- if (proto.type == "boiler") or (proto.name == HI.protoName) then
    -- return false
    -- end
    if (EntDB.globalWhitelist[proto.name]) or (EntDB.ammoTypes[proto.type]) or (proto.guns) or (proto.type == "character") or (proto.burner_prototype) then return true end
    return false
end

function SL.allSlotsQ()
    local slotQ = idQ.newSlotQ(true)
    for id, obj in pairs(DB.getEntries(SL.dbName)) do
        local slot = SL.getObj(id)
        if (slot) then slotQ:push(slot) end
    end
    return slotQ
end

function SL.entNeedsProvided(ent)
    if (not isValid(ent)) then return false end
    -- if SL.entCanMove(ent) or (ent.type == "inserter") or (ent.name:find("meteor")) then
    if SL.entCanMove(ent) or (ent.name:find("meteor")) then return true end
end

---@return fun():Slot
function SL.iterDB() return DB.iter(SL.dbName) end

---@param ent LuaEntity
---@return Slot[]
function SL.trackAllSlots(ent)
    local newSlots = {}
    if (not isValid(ent)) or (not SL.entIsTrackable(ent)) then return newSlots end
    if (isValid(ent.burner)) then newSlots = Array.merge(newSlots, SL.createSlots(ent, ent.burner.inventory, true)) end
    if (ent.type == "car") or (ent.type == "spider-vehicle") then
        local ammoInv = ent.get_inventory(defines.inventory.car_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    elseif (ent.type == "character") then
        local ammoInv = ent.get_inventory(defines.inventory.character_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
        local ammoInv = ent.get_inventory(defines.inventory.character_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    elseif (ent.type == "ammo-turret") then
        local ammoInv = ent.get_inventory(defines.inventory.turret_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    elseif (ent.type == "artillery-turret") then
        local ammoInv = ent.get_inventory(defines.inventory.artillery_turret_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    elseif (ent.type == "artillery-wagon") then
        -- cInform("attempt track artillery wagon")
        local ammoInv = ent.get_inventory(defines.inventory.artillery_wagon_ammo)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    elseif (ent.name == "repair-turret") then
        -- cInform("attempt track repair turret")
        local ammoInv = ent.get_inventory(defines.inventory.roboport_material)
        newSlots = Array.merge(newSlots, SL.createSlots(ent, ammoInv))
    end
    return newSlots
end

function SL.createSlots(ent, inv, isBurner)
    if (not isValid(ent)) or (not isValid(inv)) then return {} end
    local res = {}
    local limit = 1
    if (not isBurner) and (ent.type == "car" or ent.type == "character" or ent.type == "spider-vehicle") then
        limit = #inv
    end
    for i = 1, limit do
        local newSlot = SL.new(ent, inv.index, i, isBurner)
        if (newSlot) then table.insert(res, newSlot) end
    end
    return res
end

function SL.setGhostTags(ent, tags)
    local obj = { ghostEnt = ent, tags = tags }
    storage.ghostTags[ent.unit_number] = obj
end

---Attempt to create new Slot
---@param ent LuaEntity
---@param inv LuaInventory
---@param index integer
---@param slotCat string
---@param slotType string
---@return Slot
function SL.new(ent, invIndex, slotIndex, isBurner)
    if (not isValid(ent)) then return end
    slotIndex = slotIndex or 1
    local ind = slotIndex
    local burner
    local inv
    local itemSlot
    if (isBurner) then
        burner = ent.burner
        inv = burner.inventory
        invIndex = "burner"
        if (isValid(inv)) and (#inv >= slotIndex) and (isValid(inv[slotIndex])) then itemSlot = inv[slotIndex] end
    else
        inv = ent.get_inventory(invIndex)
        if (isValid(inv)) and (#inv >= slotIndex) and (isValid(inv[slotIndex])) then itemSlot = inv[slotIndex] end
    end
    if (not isValid(inv)) or (not isValid(itemSlot)) then return end
    local slot = itemSlot
    local perfMode = gSets.performanceModeEnabled()
    ---@class Slot
    local obj = {}
    setmetatable(obj, SL.objMT)
    obj.ent = ent
    -- obj._ammoFilter = {}
    local entName = ent.name
    -- obj._entName = entName
    if (perfMode) then
        obj._entName = entName
        obj._forceName = ent.force.name
        obj._surfaceIndex = ent.surface.index
    end
    local protoInfo = EntDB.proto(entName)
    if (invIndex ~= 1) then obj._invInd = invIndex end
    if (slotIndex ~= 1) then obj._slotInd = slotIndex end
    local force = Force.get(obj.ent.force.name)
    local slotCat, slotType, slotCats = EntDB.getSlotCatAndType(ent, invIndex, slotIndex)
    if (not slotCat) or (not slotType) then return end
    if (perfMode) then
        obj._category = slotCat
        obj._type = slotType
    end
    local slotProto = EntDB.slotProto(entName, invIndex, slotIndex)
    if (SL.entCanMove(ent)) then
        protoInfo.canMove = true
    elseif (perfMode) then
        obj._position = ent.position
    end
    if (SL.entNeedsProvided(ent)) then
        protoInfo.needsProvided = true
        obj._slot = slot
    end
    if (perfMode) then
        obj._inv = inv
        obj._slot = itemSlot
    end
    if (ent.type == "character") then
        protoInfo.isCharacter = true
        protoInfo.isChar = true
        obj._categories = {}
        obj._isChar = true
        if (isValid(ent.player)) then
            obj._playerInd = ent.player.index
        end
    end
    if (slotType == "fuel") then
        slotProto.fillLimit = 5
    else
        slotProto.fillLimit = ent.prototype.automated_ammo_count or 10
        if (slotProto.category == "artillery-shell") then slotProto.fillLimit = 5 end
    end
    obj._highlightRenderID = nil
    local enabled = obj:checkEnabled()
    if (not enabled) then return end
    obj._ammoFilter = {}
    obj._ammoFilterMode = util.FilterModes.blacklist
    obj.id = DB.insert(SL.dbName, obj)

    if (not protoInfo.needsProvided) then
        local insEnt = HI.new(obj)
        obj._inserterEnt = insEnt
    end
    if (obj:isCharacter()) then
        local pl = obj:charPlayer()
        if (pl) then
            Handlers.playerGunChanged({
                player_index = pl.index
            })
        end
    else
        -- obj:queueUrgentProvCheck()
        -- force.slotsNeedCheckBestProv:push(obj, true)
    end
    obj._isValid = nil
    obj._validCheckTick = 0

    if (storage.persist.slotFilters) then
        for i, filterInfo in pairs(storage.persist.slotFilters) do
            if (filterInfo.ent) and (filterInfo.ent == ent) then
                obj._ammoFilter = filterInfo.filters
                obj._ammoFilterMode = filterInfo.filterMode
                storage.persist.slotFilters[i] = nil
                break
            end
        end
    end

    force:addSlot(obj)
    return obj
end

function SL:itemInfo(itemName) return self:force():itemInfo(itemName) end

function SL:getItemByRank(cat, rank) return self:force():getItemByRank(cat, rank) end

SL.itemByRank = SL.getItemByRank

function SL:entName() return self._entName or self.ent.name end

function SL:slotProto() return EntDB.slotProto(self:entName(), self:invInd(), self:slotInd()) end

function SL:fillLimit() return settings.global[protoNames.settings.itemFillSize].value or self:slotProto().fillLimit end

function SL:needsProvided()
    if (self._needsProvided == nil) then
        if (gSets.performanceModeEnabled()) then
            self._needsProvided = storage.EntDB.entProtos[self:entName()].needsProvided
            return self._needsProvided
        end
        return storage.EntDB.entProtos[self:entName()].needsProvided
    end
    return self._needsProvided
end

function SL:isCharacter()
    if (self._isChar == nil) then
        if (gSets.performanceModeEnabled()) then
            self._isChar = storage.EntDB.entProtos[self:entName()].isChar
            return self._isChar
        else
            return storage.EntDB.entProtos[self:entName()].isChar
        end
    end
    return self._isChar
end

function SL:charPlayer()
    local ent = self.ent
    if (not self:isCharacter()) or (not isValid(ent)) or (not isValid(ent.player)) then return end
    return ent.player
end

function SL:invInd() return self._invInd or 1 end

function SL:slotInd() return self._slotInd or 1 end

---@param newCat alAmmoCategory
function SL:setCategory(newCat)
    if (not newCat) then
        self._categories = {}
        return
    end
    self._categories = { newCat = true }
end

function SL:setCategories(catList)
    local cats = {}
    for ind, cat in pairs(catList) do
        cats[cat] = true
    end
    self._categories = cats
end

---@return alAmmoCategory
function SL:category()
    if (self._category ~= nil) then
        return self._category
    end
    if (self._categories ~= nil) then
        return self._categories[1] or ''
    end
    return self:slotProto().categories[1] or ""
end

---@return Hash<alAmmoCategory, boolean>
function SL:categories()
    local isEmpty = table.isEmpty
    if (self._categories == nil) and (not self:isCharacter()) then
        local slotInfo = self:slotProto()
        if (slotInfo) and (not isEmpty(slotInfo.categoryHash)) then return slotInfo.categoryHash end
        local cat = self:category()
        if (not cat) then return {} end
        return { cat = true }
    end
    return self._categories
end

---@param cat alAmmoCategory
---@return boolean
function SL:hasCategory(cat)
    -- local hasCat = self:categories()[cat]
    -- cInform('hasCategory: '..cat..', '..tostring(hasCat))
    if (not self:categories()[cat]) then return false end
    return true
end

function SL:canMove()
    if (self._canMove == nil) then
        if (gSets.performanceModeEnabled()) then
            self._canMove = storage.EntDB.entProtos[self:entName()].canMove
            return self._canMove
        else
            return storage.EntDB.entProtos[self:entName()].canMove
        end
    end
    return self._canMove
end

-- @return alItem
-- function SL:getItemInfo(arg)
--     local t = type(arg)
--     local inf
--     if (t == "number") then
--         inf = self:itemByRank(arg)
--     elseif (t == "string") then
--         inf = self:itemInfo(arg)
--     elseif (t == "table") then
--         inf = arg
--     end
--     return inf
-- end

function SL:isProvided()
    if (self._isProvided ~= nil) then return self._isProvided end
    if (self:needsProvided()) then return true end
    local sourceID = self:sourceID()
    if (sourceID) then
        local prov = TC.getObj(sourceID)
        if (prov) then
            -- Use surface.index for comparison - more reliable than surface.name
            if (prov:surfaceIndex() ~= self:surfaceIndex()) then
                return true
            end
        else
            self:setSourceID(nil)
            return false
        end
    end
    return false
end

--- @param chest Chest
function SL:isInRange(chest)
    return util.isInRange(self, chest)
end

function SL:netIsInRange(chest)
    if (gSets.rangeIsInfinite()) then return true end
    if (not chest) or (not chest._networkID) then return false end
    local netsInRange = self:netsInRangeHash()
    if (netsInRange[chest._networkID]) then return true end
    return false
end

function SL:area()
    local rad = gSets.chestRadius()
    if rad > 0 then return Position.expand_to_area(self:position(), rad) end
    return nil
end

---Get this Slot's LuaSurface.
---@return LuaSurface
function SL:surface()
    local idx = self._surfaceIndex
    if idx then
        return game.surfaces[idx]
    end
    return self.ent.surface
end

---@return number
function SL:surfaceIndex() return self._surfaceIndex or self.ent.surface.index end

---@return string
function SL:surfaceName() return self:surface().name end

---@return LuaInventory
function SL:inv()
    if (self._inv) then return self._inv end
    local invInd = self:invInd()
    if (invInd == "burner") then return self.ent.burner.inventory end
    return self.ent.get_inventory(invInd)
end

---Get the LuaItemStack corresponding to this object's inventory slot.
---@return LuaItemStack
function SL:slot() return self._slot or self:inv()[self:slotInd()] end

function SL:slotItem()
    if (self._slotItem) then return self._slotItem end
    local stack = self:itemStack()
    if (not stack) or (stack.count <= 0) then return end
    return stack.name
end

function SL:slotItemInfo() return self:itemInfo(self:slotItem()) end

---@return LuaEntity
function SL:inserterEnt()
    if (self._inserterEnt) then
        return self._inserterEnt
    end
    if (self:needsProvided()) then
        return
    end

    local inserters = self:surface().find_entities_filtered {
        area = self.ent.bounding_box,
        name = HI.protoName,
        limit = 1
    }
    for i = 1, #inserters do
        local ins = inserters[i] ---@type LuaEntity
        if (isValid(ins)) then return ins end
    end
end

---Gets the LuaItemStack from this slot's inserter's held_stack. If copy is true, will return a new SimpleItemStack instead. If copy is false but no valid held_stack is found, will return nil.
---@param copy boolean
---@return LuaItemStack
function SL:inserterHeldStack(copy)
    local insEnt = self:inserterEnt()
    if (isValid(insEnt)) then
        local heldStack = insEnt.held_stack
        if (not util.stackIsEmpty(heldStack)) then
            if (copy) then
                return {
                    name = heldStack.name,
                    count = heldStack.count
                }
            else
                return heldStack
            end
        end
    end
    if (copy) then
        return SL.emptyStack()
    else
        return nil
    end
end

--- #### Attempt to return the slot inserter entity's held_stack. Will try pickup_target, drop_target, and force storage in that order.
---@param spillRemains boolean @##### If true, the held stack will be spilled on the ground as a last resort.
---@return ItemStack @##### A SimpleItemStack with the items remaining, or an empty stack.
function SL:inserterReturnHeld(spillRemains)
    local insEnt = self:inserterEnt()
    if (not isValid(insEnt)) then return SL.emptyStack() end
    local held = insEnt.held_stack
    if (util.stackIsEmpty(held)) then return SL.emptyStack() end
    local heldStack = {
        name = held.name,
        count = held.count
    }
    local pickup = insEnt.pickup_target
    if (heldStack.count > 0) and (isValid(pickup)) then
        local amtPickup = pickup.insert(heldStack)
        heldStack.count = heldStack.count - amtPickup
    end
    local drop = insEnt.drop_target
    if (heldStack.count > 0) and (isValid(drop)) then
        local amtDrop = drop.insert(heldStack)
        heldStack.count = heldStack.count - amtDrop
    end
    if (heldStack.count > 0) then
        local force = Force.get(insEnt.force.name)
        heldStack = force:sendToStorage(heldStack, nil, insEnt.position)
    end
    if (heldStack.count > 0) then
        -- cInform(
        -- "HI._init() || heldstack not empty. Stack must be spilled or lost: ",
        -- heldStack)
    end
end

---Remove Slot from database and destroy its inserter.
function SL:destroy()
    local wasDestroying = false
    if (self._destroying) then wasDestroying = true end

    self._destroying = true
    self:inserterReturnHeld(true)
    local insEnt = self:inserterEnt()
    if (isValid(insEnt)) then insEnt.destroy() end
    if (self:sourceID()) then
        local filterName = self:filterItem()
        local prov = self:provider()
        if (prov) and (filterName) then self:force():removeSlotFromProv(self, prov) end
    end
    DB.deleteID(SL.dbName, self.id)

    --For jetpack mod compatibility
    if (not wasDestroying) then self:jetpackCompatOnDestroy() end
end

function SL:jetpackCompatOnDestroy()
    if (not self._playerInd) or (not gSets.jetpackModActive()) or (isValid(self.ent)) then return end
    local otherSlots = SL.getSlotsFromPlayerIndex(self._playerInd)
    ---@param slot Slot
    for i, slot in pairs(otherSlots) do
        if (not slot._destroying) then
            slot._destroying = true
            slot:destroy()
        end
    end
    local player = game.get_player(self._playerInd)
    Handlers.jetpackCharacterRemoved(player)
    -- local pChar = player.character
    -- if (isValid(pChar)) and (pChar ~= self.ent) then
    --     Handlers.jetpackCharacterRemoved(player)
    -- end
end

---@return Position
function SL:position()
    local pos = self._position or self.ent.position
    return { x = pos.x, y = pos.y }
end

function SL:positionRounded()
    local floor = math.floor
    -- local floor = math.tointeger
    local pos = self:position()
    return { x = floor(pos.x + 0.5), y = floor(pos.y + 0.5) }
    -- return {x=floor(pos.x), y=floor(pos.y)}
end

---Get the Force this Slot belongs to.
---@return Force
function SL:force()
    -- local force = Force.forces()[self._forceName]
    return Force.get(self:forceName())
end

---Get the name of this Slot's force
---@return string
function SL:forceName()
    if (self._forceName == nil) then
        if (gSets.performanceModeEnabled()) then
            self._forceName = self.ent.force.name
        else
            return self.ent.force.name
        end
    end
    return self._forceName
end

---@return number Integer representing the current provider's ID. Nil if no current provider.
function SL:sourceID() return self._sourceID end

---Return Slot's current provider
---@return Chest
function SL:provider() return TC.getObj(self:sourceID()) end

---@return Chest
function SL:previousProvider() return TC.getObj(self:prevSourceID()) end

---@return alItem
function SL:filterInfo() return self:itemInfo(self._filterName) end

---@return string
function SL:filterItem()
    -- if (self:needsProvided()) then return self._filterName end
    -- local insEnt = self:inserterEnt()
    -- if (isValid(insEnt)) then return insEnt.get_filter(1) end
    -- return self._filterName
    return self._filterName
end

function SL:hasMoved()
    if (not self:canMove()) then return false end
    if (not self._lastPos) then
        self._lastPos = self:positionRounded()
        -- self._lastPos = self:position()
        return true
    end
    -- local pos = self:position()
    local pos = self:positionRounded()
    if (pos.x == self._lastPos.x and pos.y == self._lastPos.y) then return false end
    self._lastPos = pos
    return true
    -- if (util.distSq(pos, self._lastPos) < 1) then return false end
    -- if (table.equals(self._lastPos, pos)) then return false end
    -- self._lastPos = pos
    -- return true
end

---Check slot inventory and refill if necessary.
function SL:doProvide()
    local isEmpty = table.isEmpty
    if (not self:enabled()) then return false end
    local bestProvCalled = false
    if (self:isCharacter()) then
        local pl = self:charPlayer()
        if (isEmpty(self:categories())) or (not pl) then return end
        -- local char = pl.character
        if (not pl.is_cursor_empty()) then
            local handLoc = pl.hand_location
            local gunInvDef = defines.inventory.character_guns
            local ammoInvDef = defines.inventory.character_ammo
            local e = self.ent
            if (not util.stackIsEmpty(self.ent.cursor_stack)) and (handLoc) and (handLoc.inventory) and
                ((e.get_inventory(handLoc.inventory) == self.ent.get_inventory(gunInvDef)) or
                    (e.get_inventory(handLoc.inventory) == self.ent.get_inventory(ammoInvDef))) then
                -- cInform("SL:doProvide || player hand not empty...")
                return
            end
        end
    end
    local force = self:force()
    if (self:canMove()) then
        if (self:hasMoved()) then
            local prov = self:provider()
            if (self:sourceID()) and (not self:isInRange(prov)) then self:setProv() end
            if (not bestProvCalled) then
                self:queueUrgentProvCheck()
                -- local prov, item = force:getBestProv(self)
                -- if (prov) and (item) then
                --     self:setProv(prov, item)
                -- end
                -- force.slotsNeedCheckBestProv:push(self)
                bestProvCalled = true
            end
        end
    end
    local slotStack = self:itemStack()
    if (not bestProvCalled) and (self:sourceID()) and (self:filterItem()) and (slotStack.count <= 0) and
        (self:provider():inv().get_item_count(self:filterItem()) <= 0) then
        self:setProv()
        -- local prov, item = force:getBestProv(self)
        -- if (prov) and (item) then self:setProv(prov, item) end
        self:queueUrgentProvCheck()
        -- force.slotsNeedCheckBestProv:push(self)
        bestProvCalled = true
    end
    if (not self:sourceID()) or (not self:filterItem()) then return end
    local chest = self:provider()
    local filterItemInf = self:filterInfo()

    if (not chest) or (not filterItemInf) then return end
    local filterItem = filterItemInf.name
    local slot = self:slot()
    local slotStack = SL.emptyStack()
    if (slot.valid and slot.valid_for_read) then
        slotStack = {
            name = slot.name,
            count = slot.count
        }
    end
    if (slotStack.count > 0) and (slotStack.name ~= filterItem) then return end
    local fillLimit = self:fillLimit()
    if (filterItemInf.stackSize < fillLimit) then fillLimit = filterItemInf.stackSize end
    local amtToFull = fillLimit - slotStack.count
    if (amtToFull > 0) then
        local fillStack = {
            name = filterItem,
            count = amtToFull
        }
        local amtRemoved = chest:remove(fillStack)
        if (amtRemoved > 0) then
            fillStack.count = amtRemoved
            slot.transfer_stack(fillStack)
        end
    end
end

---set the sourceID of this Slot's HiddenInserter. For internal use only.
function SL:setSourceID(id)
    local chest = TC.getObj(id)
    if (not chest) then id = nil end
    self._sourceID = id
    local insEnt = self:inserterEnt()
    if (insEnt) and (insEnt.valid) then
        if (not chest) then
            insEnt.pickup_position = nil
        else
            insEnt.pickup_position = chest:position()
        end
    end
end

---set the filter of this Slot's HiddenInserter. For internal use only.
function SL:setFilterItem(item)
    -- if (self:needsProvided()) then
    --     self._filterName = item
    --     return
    -- end
    local insEnt = self:inserterEnt()
    if isValid(insEnt) then
        insEnt.set_filter(1, item)
        if (not item) then
            insEnt.active = false
        else
            insEnt.active = true
        end
    end
    self._filterName = item
end

---@return table<number, boolean>
function SL:netsInRangeHash()
    local res = {}
    for chest in self:force():iterChests(nil, nil, {}) do
        if (chest._networkID) and (self:isInRange(chest)) then res[chest._networkID] = true end
    end
    return res
end

---Test a provider and item to see if the item is better or the provider is closer to this slot
---@param item string
---@param chest Chest
function SL:itemIsBetterOrCloser(item, chest)
    -- serpLog("itemIsBetterOrCloser")
    if (not item) or (not chest) then return false end
    local force = self:force()
    if (not force:entFiltersAllow(self, item)) then
        if (not chest:filterSlotIsWhitelisted(self)) then
            -- cInform('force filter does not allow')
            return false
        end
    elseif (not chest:filterAllows(self)) then
        -- cInform('chest filter does not allow')
        return false
    elseif (not self:filterAllows(item)) then
        -- cInform("slot filter does not allow")
        return false
    end
    local curInf = self:filterInfo()
    local sourceID = self:sourceID()
    local newInf = self:itemInfo(item)
    local slotCats = self:categories()
    if (not newInf) or (not self:hasCategory(newInf.category)) or (not self:isInRange(chest)) then
        return false
    elseif (not curInf) or (not sourceID) then
        return true
    elseif (force.rmProvs[sourceID] and force.rmProvs[sourceID][curInf.name]) then
        return true
    elseif (newInf.category == curInf.category) then
        if (newInf.rank < curInf.rank) then
            return true
        elseif (newInf.rank == curInf.rank) and (self:compareProvsByDist(chest, self:provider())) then
            return true
        end
    elseif (newInf.category ~= curInf.category) then
        local newIsBetter = force:compareItems(newInf, curInf)
        if (newIsBetter) then
            return true
        elseif (newInf.score == curInf.score) and (self:compareProvsByDist(chest, self:provider())) then
            return true
        end
    end
    return false
end

---set this Slot's provider and item filter.
---@param chestObj Chest
---@param item string
function SL:setProv(chestObj, item)
    -- serpLog("setProv")
    local curID = self:sourceID()
    local curFilterItem = self:filterItem()
    if (not curID) and (not curFilterItem) and (not chestObj) and (not item) then
        -- serpLog("setProv exit all empty")
        return
    elseif (curID) and (chestObj) and (curID == chestObj.id) and (curFilterItem) and (item) and (curFilterItem == item) then
        -- serpLog("setProv exit no change")

        return
    end
    if (curID) and (curFilterItem) then
        self._prevSourceID = curID
    else
        self._prevSourceID = nil
    end
    local startedProvided = self:isProvided()
    local force = self:force()
    local insEnt = self:inserterEnt()
    local curProv = self:provider()
    local curFilterInfo = self:filterInfo()
    if (curProv) and (curFilterInfo) then force:removeSlotFromProv(self, curProv, curFilterInfo) end
    if (not chestObj) or (not item) then
        self._sourceID = nil
        self:setFilterItem(nil)
        if (isValid(insEnt)) then insEnt.pickup_position = nil end
    else
        self._sourceID = chestObj.id
        self:setFilterItem(item)
        if (isValid(insEnt)) then
            insEnt.pickup_position = chestObj:position()
        else
        end
        -- chestObj:addCons(self)
        force:addSlotToProv(self, chestObj, item)
    end
    if (not self:needsProvided()) then
        if (self._sourceID) then
            if (self:provider():surfaceName() == self:surfaceName()) then
                self._isProvided = false
            else
                self._isProvided = true
            end
        else
            self._isProvided = false
        end
    else
        self._isProvided = true
    end
    if (self._isProvided) and (not startedProvided) then
        force.providedSlots:pushleft(self)
        if (isValid(insEnt)) then insEnt.active = false end
    elseif (not self._isProvided) and (startedProvided) then
        force.providedSlots:softRemove(self)
        if (isValid(insEnt)) then insEnt.active = true end
    end
end

---Check if this Slot is valid.
function SL:isValid()
    if (not self) then return false end
    if (not self.ent) or (not self.ent.valid) then return false end
    return true
end

---Return items currently in slot to provider or storage.
---@param forceReturn boolean|nil Defaults to false. If true, items will be returned to anywhere possible, and dropped if there is nowhere to put them. If false, attempts to return to Loader Chest with matching items first, then to Loader Storage Chests. No action is taken if neither chest is found.
---@param slotStack LuaItemStack|nil The slot item stack. Saves UPS if passed.
---@param inserterStack LuaItemStack|nil The HiddenInserter's hand stack. Saves UPS if passed.
---@return ItemStack slotRemain, ItemStack handRemain Returns 2 ItemStacks: the slot's remaining items, and the HiddenInserter's
function SL:returnItems(forceReturn, slotStack, inserterStack)
    local force = self:force()
    local stackRemain = SL.emptyStack()
    local heldRemain = SL.emptyStack()

    local slot = slotStack or self:slot()
    if (not util.stackIsEmpty(slot)) then
        stackRemain.name = slot.name
        stackRemain.count = slot.count
    end
    local heldStack = inserterStack or self:inserterHeldStack()
    if (not util.stackIsEmpty(heldStack)) then
        heldRemain.name = heldStack.name
        heldRemain.count = heldStack.count
    end
    if (stackRemain.count + heldRemain.count <= 0) then
        cInform('nothing to return')
        return stackRemain, heldRemain
    end

    local function clear()
        local stackIsEmpty = util.stackIsEmpty
        if (not stackIsEmpty(slot)) then slot.clear() end
        if (not stackIsEmpty(heldStack)) then heldStack.clear() end
        local inv = self:inv()
        if (not self:canMove()) and (not inv.is_empty()) then
            for j = 1, #inv do
                local invStack = inv[j]
                if (not stackIsEmpty(invStack)) then
                    local i = inv[j].name
                    local c = inv[j].count
                    local remain = force:sendToStorage({
                        name = i,
                        count = c
                    })
                    local ins = c - remain.count
                    if (ins > 0) then
                        inv.remove({
                            name = i,
                            count = ins
                        })
                    end
                end
            end
        end
    end
    local function returnToChest(chest)
        if not chest then return end
        if (chest:itemAmt(stackRemain.name) > 0) then
            local stackIns = chest:insert(stackRemain)
            stackRemain.count = stackRemain.count - stackIns
        end
        if (chest:itemAmt(heldRemain.name) > 0) then
            local heldIns = chest:insert(heldRemain)
            heldRemain.count = heldRemain.count - heldIns
        end
    end
    returnToChest(self:previousProvider())
    returnToChest(self:provider())
    stackRemain.count = force:sendToStorage(stackRemain).count
    heldRemain.count = force:sendToStorage(heldRemain).count
    if (stackRemain.count + heldRemain.count <= 0) then
        clear()
        return stackRemain, heldRemain
    end
    if (forceReturn) then
        if (stackRemain.count > 0) then
            util.spillStack({
                stack = stackRemain,
                position = self:position(),
                surface = self:surface(),
                force = self.ent.force
            })
        end
        if (heldRemain.count > 0) then
            util.spillStack({
                stack = heldRemain,
                position = self:position(),
                surface = self:surface(),
                force = self.ent.force
            })
        end
        clear()
        stackRemain.count = 0
        heldRemain.count = 0
        return stackRemain, heldRemain
    end
    if (not util.stackIsEmpty(slot)) and (not util.stackIsEmpty(stackRemain)) then slot.count = stackRemain.count end
    if (not util.stackIsEmpty(heldStack)) and (not util.stackIsEmpty(heldRemain)) then
        heldStack.count = heldRemain.count
    end
    return stackRemain, heldRemain
end

-- function SL:addInserterItemsToBuffer(buffer, doDestroy)
--     if (not doDestroy) then doDestroy = true end
--     if (not isValid(self.ent)) or (not isValid(buffer)) then return end
--     local ent = self.ent
--     local inserters = ent.surface.find_entities_filtered({
--         name = HI.protoName,
--         force = ent.force.name,
--         area = ent.bounding_box
--     })
--     for i = 1, #inserters do
--         local ins = inserters[i]
--         if (isValid(ins)) then
--             local held = ins.held_stack
--             if (held) and (held.count > 0) then
--                 local amtInserted = buffer.insert({
--                     name = held.name,
--                     count = held.count
--                 })
--                 if (amtInserted >= held.count) then
--                     held.clear()
--                 else
--                     held.count = held.count - amtInserted
--                 end
--             end
--             if (doDestroy) then ins.destroy() end
--         end
--     end
-- end

---@param ent LuaEntity
function SL.entCanMove(ent)
    if (SL.typesCanMove[ent.type]) then return true end
    return false
end

---@return Slot
function SL.getObj(id) return DB.getObj(SL.dbName, id) end

---Get an array of existing slots whose parent is ent. Returns empty table if ent is invalid.
---@param ent LuaEntity
---@return Slot[]
function SL.getSlotsFromEnt(ent)
    if (not isValid(ent)) or (not SL.entIsTrackable(ent)) then return {} end
    local slots = DB.getEntries(SL.dbName)
    local result = {}
    local c = 0
    for id, slotObj in pairs(slots) do
        if (slotObj) and (slotObj.ent == ent) then
            c = c + 1
            result[c] = slotObj
        end
    end
    return result
end

---Get all slots with given parent entity in an idQ. Uses SL.getSlotsFromEnt.
---@param ent LuaEntity
---@return slotQ
function SL.getSlotsFromEntQ(ent)
    local slots = SL.getSlotsFromEnt(ent)
    local q = idQ.newSlotQ(true)
    for i = 1, #slots do q:push(slots[i]) end
    return q
end

function SL.getSlotsFromPlayerIndex(pIndex)
    local slots = DB.getEntries(SL.dbName)
    local result = {}
    local c = 0
    ---@param slotObj Slot
    for id, slotObj in pairs(slots) do
        if (slotObj) and (slotObj._playerInd == pIndex) then
            c = c + 1
            result[c] = slotObj
        end
    end
    return result
end

---@return ItemStack
function SL:itemStack()
    local slot = self:slot()
    if (not slot.valid or not slot.valid_for_read) then return SL.emptyStack() end
    return {
        name = slot.name,
        count = slot.count
    }
end

function SL:slotType() return self._type or self:slotProto().type end

function SL:checkEnabled()
    local enabled = true
    local force = self:force()
    local type = self:slotType()
    if (type == "fuel") and (not force:doFuel()) then
        enabled = false
    elseif (type == "fuel") and (not self:canMove()) and (not force:doBurners()) then
        enabled = false
    elseif (self:hasCategory() == "artillery-shell") and (not force:doArtillery()) then
        enabled = false
    elseif ((self.ent.type == "car") or (self.ent.type == "locomotive")) and (not force:doVehicles()) then
        enabled = false
    elseif (self.ent.type == "locomotive") and (not gSets.doTrains()) then
        enabled = false
    end
    return enabled
end

function SL:disable()
    self:setProv()
    self._disabled = true
end

function SL:enable()
    self._disabled = nil
    -- self:force().slotsNeedCheckBestProv:push(self)
    self:queueUrgentProvCheck()
end

function SL:enabled()
    if (self._disabled) then return false end
    return true
end

function SL:highlight(player)
    if (not isValid(self.ent)) or (not isValid(player)) or (player.surface.name ~= self:surfaceName()) or
        (not self:sourceID()) or (not self:filterItem()) then
        return
    end
    if (self._highlightRenderID) then
        local highlightObj = rendering.get_object_by_id(self._highlightRenderID)
        if (highlightObj) then
            util.renderAddPlayer(highlightObj.id, player)
        end
    else
        local highlightRender = rendering.draw_circle({
            color = SL.slotWithProviderColor,
            radius = 0.1,
            width = 1,
            filled = true,
            target = self.ent,
            surface = self:surface().name,
            players = { player },
            draw_on_ground = false
        })
        self._highlightRenderID = highlightRender.id
    end
end

function SL.highlightEnt(ent, player)
    if (not isValid(player)) or (not isValid(ent)) or (player.surface ~= ent.surface) then return end
    local highlightRenderID1 = rendering.draw_text({
        color = { 1.0, 1.0, 1.0 },
        target = ent,
        surface = player.surface.name,
        players = { player },
        draw_on_ground = false,
        target_offset = { 0, -1.5 },
        text = { "", "AL+" },
        scale_with_zoom = true,
        visible = true,
        scale = 0.7
    })
    local highlightRenderID2 = rendering.draw_circle({
        color = SL.slotWithProviderColor,
        radius = 0.15,
        width = 1,
        filled = true,
        target = ent,
        target_offset = { 0, -0.75 },
        surface = player.surface.name,
        players = { player },
        draw_on_ground = false
    })

    if (gSets.debugging()) then
        local slots = SL.getSlotsFromEnt(ent)
        for ind, slot in pairs(slots) do
            local slotStack = slot:slot()
            local slotStackItemName = 'nil'
            if (slotStack.valid and slotStack.valid_for_read) then slotStackItemName = slotStack.name end
            cInform(string.format('slot %d: id->%s | sourceID->%s | filterItem->%s | stackItem->%s', ind,
                tostring(slot.id),
                tostring(slot:sourceID()), tostring(slot:filterItem()), slotStackItemName))
        end
    end
end

---@param player LuaPlayer
function SL:drawLineToProvider(player)
    if (not isValid(self.ent)) or (not isValid(player)) or (not isValid(player.character)) or (player.character.surface.name ~= self.ent.surface.name) then return end
    local prov = self:provider()
    if (not prov) or (prov.ent.surface.name ~= self.ent.surface.name) then return end

    return rendering.draw_line({
        color = {
            r = 0.5,
            g = 0,
            b = 0.5,
            a = 0.2
        },
        -- color = util.colors.purple,
        width = 1,
        from = self.ent,
        to = prov.ent,
        surface = self.ent.surface,
        players = { player },
        draw_on_ground = false
    })
end

function SL:queueUrgentProvCheck()
    local cats = self:categories()
    -- local catNum = #cats
    -- if (catNum <= 0) then return end
    local force = self:force()
    for cat, t in pairs(cats) do
        -- local cat = cats[i]
        local catProvs = force.urgentProvCats[cat]
        if (not catProvs) then return end
        for itemRank, provs in pairs(catProvs) do for provID, q in pairs(provs) do q:push(self) end end
    end
end

--- returns true if id1 is closer to the TrackedSlot than id2
--- @param id1 number
---@param id2 number
---@return boolean is_id1_closer True if the first argument is closer, false if they are tied or second argument is closer.
function SL:compareProvsByDist(id1, id2)
    local prov1 = TC.getObj(id1)
    local prov2 = TC.getObj(id2)
    if (prov1) and (not prov2) then return true end
    if (not prov1) then return false end

    local slotSurf = self:surfaceName()
    local prov1Surf = prov1:surfaceName()
    local prov2Surf = prov2:surfaceName()
    if (prov1Surf ~= prov2Surf) then
        if (prov1Surf == slotSurf) then
            return true
        elseif (prov2Surf == slotSurf) then
            return false
        else
            return false
        end
    elseif (prov1Surf ~= slotSurf) then
        return false
    end

    local slotPos = self:position()
    local prov1Pos = prov1:position()
    local prov2Pos = prov2:position()
    -- local dist1 = self:distanceSquared(prov1)
    -- local dist2 = self:distanceSquared(prov2)
    local dist1 = util.distanceSquared(slotPos, prov1Pos)
    local dist2 = util.distanceSquared(slotPos, prov2Pos)
    if (dist1 < dist2) then return true end
    return false
end

function SL:needsReturn()
    if (not self:force():doReturn()) then return false end
    cInform('do return pass')
    local slotInf = self:slotItemInfo()
    if (not slotInf) then return false end
    local filterInf = self:filterInfo()
    if (not filterInf) then return false end
    if (filterInf.category ~= slotInf.category) then
        if (filterInf.score > slotInf.score) then return true end
    elseif (filterInf.rank < slotInf.rank) then
        return true
    end
    return false
end

--- @return fun():Slot
function SL.slotIter(limit, startID) return DB.iter(SL.dbName, limit, startID) end

-- --- **Attempt to return a stack of items to the slot's provider, previous provider, or open loader storage chests in that order.**
-- ---@param stack ItemStack
-- ---@param spillRemains boolean @ If true, spill whatever could not be returned onto the ground.
-- ---@return ItemStack Stack of items that were unable to be returned.
-- function SL:tryReturnStack(stack, spillRemains)
--     if (not stack) or (stack.count <= 0) then return SL.emptyStack() end
--     local prov = self:provider()
--     local prevProv = self:previousProvider()
--     if (stack.count > 0) and (prov) then
--         local amtToInsert = prov:amtCanReturn(stack)
--         if (amtToInsert > 0) then
--             local amtInserted = prov:insert({
--                 name = stack.name,
--                 count = amtToInsert
--             })
--             stack.count = stack.count - amtInserted
--         end
--     end
--     if (stack.count > 0) and (prevProv) then
--         local amtToInsert = prevProv:amtCanReturn(stack)
--         if (amtToInsert > 0) then
--             local amtInserted = prevProv:insert({
--                 name = stack.name,
--                 count = amtToInsert
--             })
--             stack.count = stack.count - amtInserted
--         end
--     end
--     if (stack.count > 0) then
--         local remain = self:force():sendToStorage(stack, self)
--         stack.count = remain.count
--     end
--     if (stack.count > 0) and (spillRemains) then
--         -- cInform(
--         -- "SL:tryReturnStack || not empty. Stack must be spilled or lost: ",
--         -- stack)
--         -- cInform("spilling...")
--         self:surface().spill_item_stack(self:position(), stack, false, self:forceName(), false)
--         stack.count = 0
--     end
--     return stack
-- end

---Calculate the center of the slot's parent entity's bounding box. Returns nil if slot's entity is invalid.
---@return Position
function SL:boundingBoxCenter()
    local ent = self.ent ---@type LuaEntity
    if (not isValid(ent)) or (not ent.bounding_box) then return end
    local box = ent.bounding_box
    local xMid = (box.left_top.x + box.right_bottom.x) / 2.0
    local yMid = (box.left_top.y + box.right_bottom.y) / 2.0
    local midPos = {
        x = xMid,
        y = yMid
    }
    return midPos
end

function SL:ammoFilterSwitchVal()
    local mode = util.FilterModes.whitelist
    local val = "left"
    if (self._ammoFilterMode) then mode = self._ammoFilterMode end
    if (mode == util.FilterModes.blacklist) then val = "right" end
    return val
end

function SL:setAmmoFilter(newFilter, newMode)
    if not newFilter then newFilter = {} end
    if not newMode then newMode = util.FilterModes.blacklist end
    if (not table.equals(newFilter, self._ammoFilter)) or (self._ammoFilterMode ~= newMode) then
        local itemStack = self:itemStack()
        self._ammoFilter = newFilter
        self._ammoFilterMode = newMode
        if (itemStack.count > 0) then
            -- if (itemStack.count > 0) and (not self:filterAllows(itemStack.name)) then
            self:returnItems(false)
        end
        self:setProv()
        self:queueUrgentProvCheck()
    end
end

---Check chest's entity filters to see if a slot will pass
---@param slot Slot
function SL:filterAllows(item)
    local itemInf = self:itemInfo(item)
    if (not itemInf) then
        cInform('SL:filterAllows no item info')
        return false
    end
    -- local filters = self:releventFilters()
    local filters = self._ammoFilter
    -- if (table.isEmpty(filters)) then return true end
    local ammoName = itemInf.name
    if (filters[ammoName]) then
        if (self._ammoFilterMode == util.FilterModes.whitelist) then
            -- cInform('SL:filterAllows true')
            return true
        elseif (self._ammoFilterMode == util.FilterModes.blacklist) then
            -- cInform('SL:filterAllows false')
            return false
        end
    else
        if (self._ammoFilterMode == util.FilterModes.whitelist) then
            -- cInform('SL:filterAllows false')
            return false
        elseif (self._ammoFilterMode == util.FilterModes.blacklist) then
            -- cInform('SL:filterAllows true')
            return true
        end
    end
end

return SL
