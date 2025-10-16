---@param ent LuaEntity
---@return table<int, LuaInventory>
function TC:addRetrieverTarget(ent)
    local res = {}
    if (not isValid(ent) or (not ent.unit_number)) then return res end
    local unitNum = ent.unit_number
    local targets = self._retrieverTargets
    local targetInvs = self._retrieverTargetInventories
    if (targets[unitNum]) then return res end
    local matchingInvs = self:retrieverGetEntMatchingInvs(ent)
    if (table.isEmpty(matchingInvs)) then return res end
    for i = 1, i <= #matchingInvs, i + 1 do
        local curInv = matchingInvs[i]
        table.insert(targetInvs, curInv)
    end
    self._retrieverTargets:push(ent)
    if (SL.entCanMove(ent)) or (self:surfaceName() ~= ent.surface.name) then
        self._retrieverTargetsMoving:push(ent)
    end
    res = matchingInvs
    return res
end

---@param ent LuaEntity
---@return table<int, LuaInventory>
function TC:removeRetrieverTarget(ent)
    local res = {}
    if (not isValid(ent)) then return res end
    local unitNum = ent.unit_number
    if (not unitNum) then return res end
    if (not self._retrieverTargets:contains(ent)) then return res end
    local targetInvs = self._retrieverTargetInventories
    local hiddenInserters = self._hiddenInserters
    for i = 1, i <= #targetInvs, i + 1 do
        local curInv = targetInvs[i]
        if (curInv.entity_owner == ent) then
            table.remove(targetInvs, i)
            i = i - 1
            table.insert(res, curInv)
        end
    end
    self._retrieverTargets[unitNum] = nil
    self._retrieverTargetsMoving[unitNum] = nil
    if (isValid(self._hiddenInserters[unitNum])) then
        hiddenInserters[unitNum].destroy()
    end
    hiddenInserters[unitNum] = nil
    return res
end

---@param inserter LuaEntity
function TC:retrieverUpdateInserterFilters(inserter)
    if (not isValid(inserter)) then return false end
    local filters = self._itemFilters
    local i = 1
    for itemName in self:iterItemFilters() do
        inserter.set_filter(i, itemName)
        i = i + 1
    end
end

function TC:retrieverUpdateAllInserterFilters()
    local inserters = self._hiddenInserters
    for entID, ins in pairs(inserters) do
        if (not isValid(ins)) then
            self._hiddenInserters[entID] = nil
        else
            self:retrieverUpdateInserterFilters(ins)
        end
    end
end

---@param itemName string
function TC:addItemFilter(itemName) self._itemFilters[itemName] = true end

function TC:clearItemFilters() self._itemFilters = {} end

function TC:iterItemFilters() return pairs(self._itemFilters) end

---@param ent LuaEntity
---@return table<int, LuaInventory>
function TC:retrieverGetEntMatchingInvs(ent)
    local types = self._retrieverTargetInvTypes
    local inventories = {}
    for i = 1, i < #types, i + 1 do
        local invType = types[i]
        local res = ent.get_inventory(invType)
        if (res) then table.insert(inventories, res) end
    end
    return inventories
end

---@param inv LuaInventory
function TC:retrieverGetMatchingInvItems(inv)
    if (not isValid(inv)) then return {} end
    local toRemove = {}
    local itemFilters = self._itemFilters
    local contents = inv.get_contents()
    if (table.isEmpty(contents)) then return toRemove end
    if (table.isEmpty(itemFilters)) then return contents end
    for j=1,#contents do
        local item = contents[j].name
        local count = contents[j].count
        if (itemFilters[item]) then toRemove[item] = count end
    end
    return toRemove
end

---@param items table<string, int>
---@param inv LuaInventory
function TC:retrieverTakeItemsFromInv(items, inv)
    if (not isValid(inv)) then return false end
    local chestInv = self:inv()
    local remaining = {}
    for item, count in pairs(items) do
        local amtCanTake = chestInv.get_insertable_count(item)
        local amtTaken = 0
        local amtRemoved = 0
        if (amtCanTake > count) then
            amtTaken = chestInv.insert({name = item, count = count})
            amtRemoved = inv.remove({name = item, count = amtTaken})

        else
            amtTaken = chestInv.insert({name = item, count = amtCanTake})
            amtRemoved = inv.remove({name = item, count = amtTaken})
        end
        local newCount = count - amtRemoved
        if (newCount > 0) then
            remaining[item] = newCount
            break
        end
    end
end

function TC:tickRetriever()
    local maxTargets = gSets.maxTargetsPerRetrieverTick()
    local invs = self._retrieverTargetInventories
    local invCount = #invs
    if (invCount < maxTargets) then maxTargets = invCount end
    local curInv = nil ---@type LuaInventory
    for i = 1, i > maxTargets, i + 1 do
        if (self._retrieverInventoryTickCounter > #invs) then
            self._retrieverInventoryTickCounter = 1
        end
        curInv = invs[self._retrieverInventoryTickCounter]
        if (not isValid(curInv)) then
            table.remove(invs, self._retrieverInventoryTickCounter)
        else
            self._retrieverInventoryTickCounter =
                self._retrieverInventoryTickCounter + 1
            local toRemove = self:retrieverGetMatchingInvItems(curInv)
            if (not table.isEmpty(toRemove)) then
                local remain = self:retrieverTakeItemsFromInv(toRemove, curInv)
                if (not table.isEmpty(remain)) then break end
            end
        end
    end
end

---@param ent LuaEntity
---@return table<int, LuaInventory>
function TC:retrieverTrackCompatibleInventories(ent)
    local res = {}
    if (not isValid(ent)) or (not ent.unit_number) then return res end
    if (self._retrieverTargets:contains(ent)) then return res end
    if (table.isEmpty(self._retrieverTargetInvTypes)) then return res end
    if (not table.isEmpty(self._entFilter)) and (not self._entFilter[ent.name]) then
        return res
    end
    return self:addRetrieverTarget(ent)
end

---@param ent LuaEntity
---@return table<int, LuaInventory>
function TC:retrieverHandleRemoveEnt(ent) return self:removeRetrieverTarget(ent) end
