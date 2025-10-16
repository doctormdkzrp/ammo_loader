---@alias alItemCatName : string
---@alias alProvID : integer
---@alias alItemName : string
---@alias alItemRank : integer
---@alias alSlotIterCurVal : integer

---@class ProviderRegistryCategories
---@field [alItemCatName] ProviderRegistryItems

---@class ProviderRegistryItems
---@field [alItemRank] ProviderRegistryProviders

---@class ProviderRegistryProviders
---@field [alProvID] alSlotIterCurVal

---@class Force
Force = {}
Force.objMT = {
    __index = Force
}
Force.className = "Force"

Force._init = function()
    storage["Force"] = {}
    storage["Force"]["forces"] = {}
    local forces = storage["Force"]["forces"]
    for forceName, force in pairs(game.forces) do
        forces[forceName] = Force.new(forceName)
        -- forces[forceName].itemDB = forces[forceName]:copyItemDB()
        -- serpLog(forces[forceName].itemDB)
    end
end
-- Init.registerFunc(Force._init)

Force._onLoad = function()
    for name, frc in pairs(Force.forces()) do
        setmetatable(frc, Force.objMT)
        setmetatable(frc.needRemoveProv, Queue.objMT)
        for key, meta in pairs(Force.metaVars) do setmetatable(frc[key], meta) end
        for catName, catProvs in pairs(frc.urgentProvCats) do
            for itemRank, itemProvs in pairs(catProvs) do
                for provID, slotQ in pairs(itemProvs) do setmetatable(slotQ, idQ.objMT) end
            end
        end
        for catName, catProvs in pairs(frc.provCats) do
            for itemRank, itemProvs in pairs(catProvs) do
                for provID, slotQ in pairs(itemProvs) do
                    if (type(slotQ) == "table") then setmetatable(slotQ, idQ.objMT) end
                end
            end
        end
    end
end
Init.registerOnLoadFunc(Force._onLoad)

function Force._preInit()
    if (not storage.persist) or (not storage.Force) or (not storage.Force.forces) then return end
    storage.persist.Force = {}
    -- storage.persist.Force.entFilters = {}
    -- local filters = storage.persist.Force.entFilters
    for name, frc in pairs(Force.forces()) do
        storage.persist.Force[name] = {}
        storage.persist.Force[name].entFilters = frc.entFilters
        storage.persist.Force[name].itemDB = frc.itemDB
    end
end

Init.registerPreInitFunc(Force._preInit)

Force.metaVars = {
    chests = idQ.objMT,
    slots = idQ.objMT,
    storageChests = idQ.objMT,
    slotsNeedReturnQ = idQ.objMT,
    providedSlots = idQ.objMT,
    slotsNeedUnsetProvQ = idQ.objMT,
    slotsNeedCheckBestProv = idQ.objMT

}

---@return Force
function Force.new(name)
    ---@class Force
    local obj = {}
    setmetatable(obj, Force.objMT)
    obj.name = name
    obj.chests = idQ.newChestQ(true)
    obj.slots = idQ.newSlotQ(true)
    obj.curChestID = 1
    obj.storageChests = idQ.newChestQ(true)
    obj.retrievers = idQ.newChestQ(true)
    obj.forceInv = game.create_inventory(64)
    obj.slotsNeedReturnQ = idQ.newSlotQ(true)
    obj.curCheckProvID = 1
    obj.providedSlots = idQ.newSlotQ(true)
    obj.providedSlotCurID = 1
    obj.needRemoveProv = Queue.new()
    obj.techs = {}
    obj:getTechs()
    obj.provCats = {} ---@type ProviderRegistryCategories
    obj.urgentProvCats = {} ---@type ProviderRegistryCategories
    obj.checkProvCats = {}
    obj.rmProvs = {}
    obj.slotsNeedUnsetProvQ = idQ.newSlotQ(true)
    obj.slotsNeedCheckBestProv = idQ.newSlotQ(true)
    obj.entFilters = {} ---@type forceEntFilter[]
    obj.itemDB = {
        cats = {},
        items = {}
    }
    if (storage.persist) and (storage.persist.Force) and (storage.persist.Force[obj.name]) then
        local persistObj = storage.persist.Force[obj.name]
        if (persistObj.entFilters) then
            obj.entFilters = persistObj.entFilters
            persistObj.entFilters = nil
            -- storage.persist.Force.entFilters = nil
        end
        if (persistObj.itemDB) then
            local persistDB = persistObj.itemDB
            local objDB = obj.itemDB
            for catName, catObj in pairs(persistDB.cats) do objDB.cats[catName] = catObj end
            for itemName, itemObj in pairs(persistDB.items) do objDB.items[itemName] = itemObj end
            -- for catName, cat in pairs(obj.itemDB.cats) do
            --     if (not persistDB.cats[catName]) then
            --         obj.itemDB.cats[catName] = ItemDB.cat(catName)
            --     end
            -- end
            -- obj.itemDB = persistObj.itemDB
            persistObj.itemDB = nil
        end
    end
    if (obj:itemDBNeedsUpdate()) then obj.itemDB = obj:copyItemDB() end
    -- storage.persist.Force = nil
    return obj
end

function Force:copyItemDB()
    local items = ItemDB.items()
    local cats = {}
    local newItems = {}
    for itemName, itemInf in pairs(items) do
        local catName = itemInf.category
        local catObj = cats[catName]
        if (not catObj) then
            catObj = {}
            cats[catName] = catObj
        end
        -- local newItemInf = table.deepcopy(itemInf)
        catObj[itemInf.rank] = itemInf.name
        newItems[itemInf.name] = table.deepcopy(itemInf)
    end
    return {
        cats = cats,
        items = newItems
    }
end

function Force:itemDBNeedsUpdate()
    -- serpLog(self.itemDB.items)

    local items = ItemDB.items()
    -- local ammoCats = prototypes.ammo_category
    -- local fuelCats = prototypes.fuel_category
    -- local allItems = prototypes.item
    -- local cats = {}
    -- local newItems = {}
    for catName, catProto in pairs(prototypes.ammo_category) do
        if (not self.itemDB.cats[catName]) then
            return true
        end
    end
    for catName, catProto in pairs(prototypes.fuel_category) do
        if (not self.itemDB.cats[catName]) then
            return true
        end
    end
    for itemName, itemInf in pairs(items) do if (not self.itemDB.items[itemName]) then return true end end
    return false
end

---@param itemName string
---@return alItem | nil
function Force:itemInfo(itemName)
    if (not itemName) then return end
    if (type(itemName) == "table") and (itemName.name ~= null) then return itemName end
    local inf = self.itemDB.items[itemName]
    if (not inf) then
        local t = type(itemName)
        -- if (t == "string") then
        --     local dbInf = itemInfo(itemName)
        --     if (dbInf) and (dbInf.category) then
        --         self.itemDB = self:copyItemDB()
        --         inf = self.itemDB.items[itemName]
        --     end
        if (t == "table") then inf = self.itemDB.items[itemName.name] end
        -- if (not inf) then
        --     -- local dbInf = itemInfo(itemName)
        --     -- if (dbInf) and (dbInf.category) then
        --     self.itemDB = self:copyItemDB()
        --     inf = self.itemDB.items[itemName]
        --     if (not inf) and (t == "table") then
        --         inf = self.itemDB.items[itemName.name]
        --     end
        --     -- end
        -- end
    end
    return inf
end

function Force:getProvCatObj(catName)
    local obj = self.provCats[catName]
    if (not obj) then
        self.provCats[catName] = {}
        obj = self.provCats[catName]
    end
    return obj
end

function Force:getItemByRank(cat, rank) return self:itemInfo(self.itemDB.cats[cat][rank]) end

Force.itemByRank = Force.getItemByRank

function Force:ammoCats()
    local res = {}
    local ammoCats = prototypes.ammo_category

    for catName, cat in pairs(self.itemDB.cats) do
        if (ammoCats[catName]) then res[catName] = cat end
    end
    -- serpLog('force ammoCats:')
    -- serpLog(res)
    return res
end

function Force:fuelCats()
    local res = {}
    local fuelCats = prototypes.fuel_category
    for catName, cat in pairs(self.itemDB.cats) do if (fuelCats[catName]) then res[catName] = cat end end
    return res
end

function Force:setItemRank(itemName, newRank)
    cInform("swapping item ranks")
    if (not itemName) then return end
    -- serpLog(self.itemDB)
    -- serpLog("itemName: ", itemName)
    local itemObj = self:itemInfo(itemName)
    local oldRank = itemObj.rank
    local catRanks = self.itemDB.cats[itemObj.category]
    local replaceItemObj = self:itemInfo(catRanks[newRank])
    if (itemObj) and (replaceItemObj) and (newRank ~= oldRank) and (newRank <= #catRanks) and (newRank >= 1) then
        local provCat = self:getProvCatObj(itemObj.category)
        local oldRankProvs = provCat[oldRank]
        local newRankProvs = provCat[newRank]
        provCat[oldRank] = newRankProvs
        provCat[newRank] = newRankProvs
        catRanks[oldRank] = catRanks[newRank]
        catRanks[newRank] = itemObj.name
        itemObj.rank = newRank
        replaceItemObj.rank = oldRank
        for slot in self.slots:slotIter() do
            -- slot:setProv()
            -- self.slotsNeedCheckBestProv:push(slot)
            slot:queueUrgentProvCheck()
        end
    end
end

function Force:resetItemCat(catName)
    local catItems = ItemDB.catItems(catName)
    local newCatObj = {}
    for itemRank, itemObj in pairs(catItems) do
        local newItemObj = table.deepcopy(itemObj)
        self.itemDB.items[newItemObj.name] = newItemObj
        newCatObj[newItemObj.rank] = newItemObj.name
    end
    self.itemDB.cats[catName] = newCatObj
end

function Force:resetItemDB() self.itemDB = self:copyItemDB() end

function Force:compareItems(itemName1, itemName2)
    local item1 = self:itemInfo(itemName1)
    local item2 = self:itemInfo(itemName2)

    if (item1.rank) and (item2.rank) then
        if (item1.rank < item2.rank) then
            return true
        elseif (item1.rank > item2.rank) then
            return false
        end
        return false
    elseif (item1.type == "fuel") and (item2.type == "fuel") then
        if item1.topSpeedMult > item2.topSpeedMult then
            return true
        elseif item1.topSpeedMult < item2.topSpeedMult then
            return false
        else
            if item1.accelMult > item2.accelMult then
                return true
            elseif item1.accelMult < item2.accelMult then
                return false
            else
                if item1.score > item2.score then
                    return true
                elseif item1.score < item2.score then
                    return false
                else
                    if item1.name > item2.name then
                        return true
                    elseif item1.name < item2.name then
                        return false
                    end
                end
            end
        end
    else
        if item1.score > item2.score then
            return true
        elseif item1.score < item2.score then
            return false
        elseif item1.name > item2.name then
            return true
        end
    end
    return false
end

function Force:getTechs()
    self.techs = {}
    local force = game.forces[self.name]
    local forceTechs = force.technologies
    local recipes = force.recipes
    local useTech = gSets.useTech()
    for key, name in pairs(protoNames.tech) do
        local tech = forceTechs[name]
        if not tech then return end
        if (useTech) then
            tech.enabled = true
        else
            tech.enabled = false
        end
        if (not tech.enabled) or (tech.researched) then
            if (tech.name == protoNames.tech.loader) then
                recipes[protoNames.chests.loader].enabled = true
            elseif (tech.name == protoNames.tech.requester) then
                recipes[protoNames.chests.requester].enabled = true
                recipes[protoNames.chests.passiveProvider].enabled = true
            elseif (tech.name == protoNames.tech.upgrade) then
                recipes[protoNames.chests.storage].enabled = true
            end
            self.techs[name] = true
        end
    end
    for techName, tech in pairs(forceTechs) do
        local effects = tech.prototype.effects
        for _, effect in pairs(effects) do
            if (effect.type == "unlock-recipe") and (effect.recipe:find("ammo.loader.cartridge")) then
                recipes[effect.recipe].enabled = tech.researched
            end
        end
    end
end

function Force:isResearched(techName)
    if (not gSets.useTech()) or (self.techs[techName]) then return true end
    return false
end

function Force:doUpgrade()
    if (not gSets.doUpgrade()) or (not self:isResearched(protoNames.tech.upgrade)) then return false end
    return true
end

function Force:doVehicles()
    if (self:isResearched(protoNames.tech.vehicles)) then return true end
    return false
end

function Force:doFuel()
    if (self:isResearched(protoNames.tech.burners)) then return true end
    return false
end

function Force:doArtillery()
    if (not gSets.doArtillery()) or (not self:isResearched(protoNames.tech.artillery)) then return false end
    return true
end

function Force:doBurners()
    if (not gSets.doBurners()) or (not self:isResearched(protoNames.tech.burners)) then return false end
    return true
end

function Force:doReturn()
    if (not gSets.doReturn()) or (not self:isResearched(protoNames.tech.returnItems)) then return false end
    return true
end

---@return table<string, Force>
function Force.forces()
    if (not storage.Force) then storage.Force = {} end
    if (not storage.Force.forces) then storage.Force.forces = {} end
    return storage.Force.forces
end

---Get Force by name
---@param name string|Force
---@return Force
function Force.get(name)
    if not name then return nil end
    if type(name) == 'table' then return name end
    local forces = Force.forces()
    local frc = forces[name] ---@type Force
    if not frc then
        frc = Force.new(name)
        forces[name] = frc
    end
    return frc
end

function Force.tickAll() for name, frc in pairs(Force.forces()) do frc:tick() end end

function Force:tick()
    -- if (gSets.debugging()) and (gSets.tick() % 180 == 0) then
    -- end

    -- if (tickRem == 0) then
    -- cInform('tickChests')
    self:tickChests()
    -- elseif (tickRem == 1) then
    -- cInform('tickCheckBestRmProvs')
    self:tickCheckBestRmProvs()
    -- elseif (tickRem == 2) then
    -- cInform('tickCheckBestProvs3')
    self:tickCheckBestProvs3()
    -- elseif (tickRem == 3) then
    -- cInform('tickReturn')
    self:tickReturn()
    -- elseif (tickRem == 4) then
    -- cInform('tickProvidedSlots')
    self:tickProvidedSlots()
    -- end
end

---@class betterOrCloserTable Table with chest and item for use with Slot:isBetterOrCloser().
---@field chest Chest
---@field item string

---@class slotIterFilter Table of options for use with Force:iterSlots().
---@field includeDisabled boolean
---@field category string
---@field isBetterOrCloser betterOrCloserTable
---@field inRangeOf Chest
---@field filter string
---@field filterWorseThan string
---@field filterBetterThan string
---@field sourceID number
---@field provIsFarther Chest
---@field nonMatchReturnID boolean
---@field hasProvider boolean
---@field isProvided boolean
---@field needsProvided boolean
---@field needsReturn boolean
---@field hasMoved boolean
---@field isChar boolean
---@field canMove boolean
---@field entity LuaEntity
---@field inventory LuaInventory
---@field surface LuaSurface
---@field surfaceName string
---@field insideArea Area
---@field matchesChestFilter Chest

---@param slot Slot
---@param opts slotIterFilter
function Force:slotClearsFilter(slot, opts)
    opts = opts or {}
    if (not slot) or (slot:forceName() ~= self.name) then
        return false, 'not slot or not same force'
        -- return iter()
    end
    if (not slot:enabled()) and (not opts.includeDisabled) then
        -- cInform("not enabled")
        return false, 'not enabled'
        -- return iter()
    end
    if (opts.matchesChestFilter) and (not opts.matchesChestFilter:filterAllows(slot)) then return false end
    -- if (opts.category) and (opts.category ~= slot:category()) then
    if (opts.category) and (not slot:hasCategory(opts.category)) then
        return false, 'wrong category: ' .. opts.category .. ', ' .. slot:category()
        -- return iter()
    end
    if (opts.isBetterOrCloser) then
        local newChest = opts.isBetterOrCloser.chest
        local newItem = opts.isBetterOrCloser.item
        if (not slot:itemIsBetterOrCloser(newItem, newChest)) then
            return false, 'item is not better or closer'
            -- return iter()
        end
    end
    if (opts.inRangeOf) and (not slot:isInRange(opts.inRangeOf)) then
        return false, 'slot not in range'
        -- return iter()
    end
    if (opts.insideArea) and (not Area.inside(opts.insideArea, slot:position())) then return false, 'outside area' end
    if (opts.filter) and (opts.filter ~= slot:filterItem()) then
        return false, 'wrong filter item'
        -- return iter()
    end
    if (opts.filterWorseThan) and (slot:filterItem()) and
        (self:itemInfo(opts.filterWorseThan).rank > slot:filterInfo().rank) then
        return false, 'filter not worse than'
        -- return iter()
    end
    if (opts.filterBetterThan) and
        ((not slot:filterItem()) or (self:itemInfo(opts.filterBetterThan).rank < slot:filterInfo().rank)) then
        return false, 'filter not better than'
        -- return iter()
    end
    if (opts.sourceID) and (opts.sourceID ~= slot:sourceID()) then
        return false, 'wrong sourceID'
        -- return iter()
    end
    if (opts.hasProvider ~= nil) and util.notBoth(opts.hasProvider, slot:sourceID()) then
        return false,
            'does not have provider'
    end
    if (opts.provIsFarther) and (not slot:compareProvsByDist(opts.provIsFarther, slot:sourceID())) then
        return false, 'not provIsFarther'
        -- return iter()
    end
    if (opts.isProvided ~= nil) and util.notBoth(opts.isProvided, slot:isProvided()) then return false, 'not provided' end
    if (opts.needsProvided ~= nil) and util.notBoth(opts.needsProvided, slot:needsProvided()) then
        return false,
            'not needsProvided'
    end
    if (opts.needsReturn ~= nil) and util.notBoth(opts.needsReturn, slot:needsReturn()) then
        return false,
            'not needsReturn'
    end
    if (opts.hasMoved ~= nil) and util.notBoth(opts.hasMoved, slot:hasMoved()) then return false, 'not hasMoved' end
    if (opts.isChar ~= nil) and (slot:isCharacter() ~= opts.isChar) then return false, 'not isChar' end
    if (opts.canMove ~= nil) and util.notBoth(opts.canMove, slot:canMove()) then return false, 'not canMove' end
    if (opts.entity) and ((not slot.ent) or (slot.ent ~= opts.entity)) then return false, 'wrong entity' end
    if (opts.inventory) and (not isValid(slot:inv()) or slot:inv() ~= opts.inventory) then
        return false,
            'wrong inventory'
    end
    if (opts.surface) and (slot:surface() ~= opts.surface) then return false, 'wrong surface' end
    if (opts.surfaceName) and (slot:surfaceName() ~= opts.surfaceName) then return false, 'wrong surfaceName' end
    return true
end

---Iterate through all slots in DB, returning only those belonging to this Force and that match specified filters.
---@param limit number|nil
---@param startID number|nil
---@param opts slotIterFilter|nil possible values are {includeDisabled=(bool), category=(string), isBetterOrCloser=({chest=chest, item=string}), inRangeOf=chest, filter=string, filterWorseThan=string, filterBetterThan=string, sourceID=number(chestID), provIsFarther=chest}
---@return fun():Slot
function Force:iterSlots(limit, startID, opts)
    startID = startID or 1
    opts = opts or {}
    local i = 1
    local curID = startID
    local curIDFunc = function() return curID end
    local nonMatchFunc = curIDFunc
    local getObj = DB.getObj
    local dbName = SL.dbName
    local highest = DB.highest(dbName)
    local entries = DB.getEntries(dbName)
    local function iter()
        if (curID > highest) or ((limit) and (i > limit)) then
            return nil
        end
        --- @type Slot
        if (not entries[curID]) then
            curID = curID + 1
            if (opts.nonMatchReturnID) then return curID - 1 end
            return iter()
        end
        local slot = getObj(dbName, curID)
        curID = curID + 1
        local clearsFilter, filterReason = self:slotClearsFilter(slot, opts)
        -- if (not slot) then
        --     if (opts.nonMatchReturnID) then return curID-1 end
        --     return iter()
        -- end
        -- curID = slot.id + 1
        if (not clearsFilter) then
            -- cInform('slot failed filter: '..filterReason)
            if (opts.nonMatchReturnID) then return curID - 1 end
            return iter()
        end
        i = i + 1
        return slot
    end
    if (not opts.nonMatchReturnID) then nonMatchFunc = iter end
    return iter
end

function Force:tickProvidedSlots()
    ---@type slotIterFilter
    local max = gSets.maxProvideSlots()
    local c = 0
    local provSlots = self.providedSlots
    local getSlot = SL.getObj
    while (c < max) and (c < provSlots:size()) do
        c = c + 1
        local slot = provSlots:pop() ---@type Slot
        if (not slot) then break end
        if (slot:isProvided()) then
            slot:doProvide()
            provSlots:push(slot)
            -- else
            -- cInform("not provided")
        end
    end
end

---@class iterChestsOptions Table for use with Force:iterChests() defining optional filters.
---@field chestTypes Hash<string, boolean>
---@field nonMatchReturnID boolean
---@field insideArea Area

---Returns a function(iterator) that, when called, gives a single chest in the database belonging to this force and matching all set filters.
---@param limit number Maximum number of iterations to perform.
---@param startID number Start at this ID in the database. Continues up from there.
---@param opts iterChestsOptions
---@return fun():Chest
function Force:iterChests(limit, startID, opts)
    limit = limit or nil
    startID = startID or 1
    opts = opts or {} ---@type iterChestsOptions
    local i = 1
    local curID = startID
    local highest = DB.highest(TC.dbName)
    local getObj = DB.getObj
    local nonMatchFunc = function() return curID end
    local function iter()
        if (curID > highest) or ((limit) and (i > limit)) then return end
        --- @type Chest
        local chest = getObj(TC.dbName, curID)
        curID = curID + 1
        if (not chest) or (chest:forceName() ~= self.name) then return nonMatchFunc() end
        -- if (opts.storage) and (not chest:isStorage()) then return nonMatchFunc() end
        if (opts.chestTypes) and (not opts.chestTypes[chest._mode]) then return nonMatchFunc() end
        if (opts.insideArea) and (not Area.inside(opts.insideArea, chest:position())) then return nonMatchFunc() end
        i = i + 1
        return chest
    end
    if (not opts.nonMatchReturnID) then nonMatchFunc = iter end
    return iter
end

function Force:tickChests()
    -- cInform('chests: ', self.chests.entries)
    local numChests = self.chests:size()
    local min = math.min
    if (numChests <= 0) then return end
    local i = 0
    local limit = min(gSets.chestsPerCycle, numChests)
    for chest in self:iterChests(1, self.curChestID, {
        nonMatchReturnID = true
    }) do
        if (type(chest) == "number") then
            self.curChestID = chest + 1
        else
            i = i + 1
            self.curChestID = chest.id + 1
            chest:tick()
        end
        if self.curChestID > DB.highest(TC.dbName) then
            self.curChestID = 1
        end
        if i >= limit then
            return
        end
    end
end

function Force:tickReturn()
    if (not self:doReturn()) or (self.slotsNeedReturnQ:isEmpty()) then return end
    cInform('doReturn pass')
    for slot in self.slotsNeedReturnQ:slotIter(gSets.maxReturnSlots, true) do
        if (slot:needsReturn()) then
            local remain = slot:returnItems()
            if (remain.count > 0) then self.slotsNeedReturnQ:push(slot) end
        else
            cInform('slot does not need return')
        end
    end
end

function Force:enableReturn()
    for slot in self:iterSlots() do if (slot:needsReturn()) then self.slotsNeedReturnQ:push(slot) end end
end

function Force:enableUpgrade() for slot in self:iterSlots() do slot:queueUrgentProvCheck() end end

---@param chestObj Chest
function Force:addChest(chestObj)
    self.chests:push(chestObj)
    -- chestObj:tick()
    -- for slot in self.slots:slotIter(nil,false) do
    -- end
end

---@param chestObj Chest
function Force:addStorage(chestObj)
    local isFirst = self.storageChests:isEmpty()
    self.storageChests:push(chestObj)
    if (isFirst) then
        for slot in self:iterSlots() do
            slot:queueUrgentProvCheck()
            -- self.slotsNeedCheckBestProv:push(slot)
        end
    end
end

---@param chestObj Chest
function Force:addRetriever(chestObj) self.retrievers:push(chestObj) end

---@param slotObj Slot
function Force:addSlot(slotObj)
    -- serpLog("add slot")
    if (slotObj:isProvided()) then self.providedSlots:pushleft(slotObj) end
    self.slots:pushleft(slotObj)
    slotObj:queueUrgentProvCheck()
end

---@param ins HiddenInserter
function Force:addInserter(ins) self.inserters:push(ins) end

function Force:isValid()
    if (not self) then return false end
    if game.forces[self.name] ~= nil then return true end
    return false
end

---@param stack ItemStack
---@param slot? Slot Slot that this stack will come from, used to test range.
---@param pos? Position Position to use to test range if slot is not provided. Ignored if slot exists.
---@return ItemStack Stack of items that were unable to be put in storage.
function Force:sendToStorage(stack, slot, pos, forceReturn)
    if (not stack) or (stack.count <= 0) then return SL.emptyStack() end
    local testArea = nil
    if (not isValid(slot)) then
        if (pos and pos.x and pos.y) then testArea = Position.expand_to_area(pos, gSets.chestRadius()) end
    else
        testArea = slot:area()
    end
    local iterOpts = {} ---@type iterChestsOptions
    iterOpts.insideArea = testArea
    iterOpts.chestTypes = {}
    iterOpts.chestTypes[TC.modes.storage] = true
    -- iterOpts.chestTypes[TC.modes.provider] = true

    local bestChest = {
        chest = nil,
        filterMatch = false
    }

    for chest in self:iterChests(nil, nil, iterOpts) do
        local filter = nil
        if (chest:isStorage()) then filter = chest.ent.storage_filter end
        local inv = chest:inv()
        if (not filter) and (not bestChest.chest) then
            if (inv.can_insert(stack)) then
                bestChest.chest = chest
                bestChest.filterMatch = false
            end
        elseif (filter) and (filter.name == stack.name) and ((not bestChest.chest) or (not bestChest.filterMatch)) then
            if (inv.can_insert(stack)) then
                bestChest.chest = chest
                bestChest.filterMatch = true
                break
            end
        end
        -- if (not filter) or (filter == stack.name) then
        -- end
    end
    if (not bestChest.chest) then
        -- if (forceReturn) then
        -- else
        return stack
        -- end
    end
    local inserted = bestChest.chest:inv().insert(stack)
    stack.count = stack.count - inserted
    if (stack.count <= 0) then stack.count = 0 end
    return stack
end

function Force:forceInvInsert(stack)
    local inv = self.forceInv
    if (not stack) or (stack.count <= 0) then return 0 end
    local insertable = inv.get_insertable_count(stack.name)
    if (insertable < stack.count) then
        if (inv.count_empty_stacks() <= 0) then
            inv.resize(#inv + 2)
            return self:forceInvInsert(stack)
        else
            cInform("warning: could not insert into force inventory for unknown reasons.")
            return 0
        end
    end
    return inv.insert(stack)
end

function Force:forceInvRemove(stack)
    local inv = self.forceInv
    if (not stack) or (stack.count <= 0) then return 0 end
    return inv.remove(stack)
end

---@param forceEmpty bool
function Force:returnAll(forceEmpty) for slot in self:iterSlots() do slot:returnItems(forceEmpty) end end

function Force:addSlotToProv(slot, chest)
    -- serpLog("add slot " .. slot.id .. " to provID " .. chest.id .. " item " ..
    -- item)
    local provQ = chest._consQ
    if (not provQ) then return end
    provQ:push(slot)
end

function Force:removeSlotFromProv(slot, chest)
    -- local provQ = self:provSlotQ(chest, item) ---@type slotQ
    local provQ = chest._consQ
    if (not provQ) then return end
    provQ:softRemove(slot)
end

---Register a chest as a provider for a specific item with the force's provider table
---@param chest Chest
---@param item string
function Force:registerProv(chest, item)
    if (not chest) or (not item) then
        return
    end
    local itemInf = self:itemInfo(item)
    chest = TC.getObj(chest)
    if (not chest) or (not itemInf) then
        return
    end
    -- serpLog("register prov itemInfo rank: ", itemInf.rank)
    local chestID = chest.id
    local provItems = self.provCats[itemInf.category] ---@type ProviderRegistryItems
    if (not provItems) then
        provItems = {}
        self.provCats[itemInf.category] = provItems
    end
    local urgentProvItems = self.urgentProvCats[itemInf.category] ---@type ProviderRegistryItems
    if (not urgentProvItems) then
        urgentProvItems = {}
        self.urgentProvCats[itemInf.category] = urgentProvItems
    end
    local provs = provItems[itemInf.rank] ---@type ProviderRegistryProviders
    if (not provs) then
        provs = {}
        provItems[itemInf.rank] = provs
    end
    local urgentProvs = urgentProvItems[itemInf.rank] ---@type ProviderRegistryProviders
    if (not urgentProvs) then
        urgentProvs = {}
        urgentProvItems[itemInf.rank] = urgentProvs
    end
    provs[chestID] = 1
    urgentProvs[chestID] = idQ.newSlotQ(true)
    self.checkProvCats[itemInf.category] = 1
    if (self.rmProvs[chestID]) then self.rmProvs[chestID][item] = nil end
end

---@param chest Chest
---@param item string
function Force:removeProv(chest, item, forceUnsetSlots)
    if (forceUnsetSlots == nil) then forceUnsetSlots = false end
    local inf = self:itemInfo(item)
    if (not inf) then return end
    local chestID = chest
    chest = TC.getObj(chest)
    if (chest) then
        chestID = chest.id
    end
    cInform(string.format('removeProv: chestID->%d | item->%s | forceUnset->%s', chestID, inf.name, forceUnsetSlots))
    if (self.provCats) and (self.provCats[inf.category]) and (self.provCats[inf.category][inf.rank]) and (self.provCats[inf.category][inf.rank][chestID]) then
        self.provCats[inf.category][inf.rank][chestID] = nil
        if (not self.rmProvs[chestID]) then self.rmProvs[chestID] = {} end
        self.rmProvs[chestID][item] = 1
        for itemRank, provs in pairs(self.provCats[inf.category]) do
            for provID, curSlotID in pairs(provs) do
                provs[provID] = 1
            end
        end
        -- if (not self.rmProvs[chestID]) then self.rmProvs[chestID] = {} end
        -- self.rmProvs[chestID][item] = 1

        -- local slotQ = self.provCats[inf.category][inf.rank][chestID] ---@type slotQ
        -- if (slotQ) then
        --     if (forceUnsetSlots) then
        --         ---@type slotIterFilter
        --         local opts = {}
        --         opts.sourceID = chestID
        --         opts.filter = inf.name

        --         for slot in self:iterSlots(nil, 1, opts) do
        --             slot:setProv()
        --             slot:queueUrgentProvCheck()
        --         end
        --     end
        --     -- self.slotsNeedUnsetProvQ:push(slot)
        --     -- self.slotsNeedCheckBestProv:push(slot)
        --     self.provCats[inf.category][inf.rank][chestID] = nil
        --     self.checkProvCats[inf.category] = 1
        -- end
    end
    if (forceUnsetSlots) then
        cInform('forceUnsetSlots')
        ---@type slotIterFilter
        local opts = {}
        opts.sourceID = chestID
        opts.filter = inf.name

        for slot in self:iterSlots(nil, 1, opts) do
            slot:setProv()
            slot:queueUrgentProvCheck()
        end
    end
    if (self.urgentProvCats) and (self.urgentProvCats[inf.category]) and (self.urgentProvCats[inf.category][inf.rank]) then
        self.urgentProvCats[inf.category][inf.rank][chestID] = nil
    end
end

function Force:removeProvID(chestID, forceUnsetSlots)
    if (forceUnsetSlots == nil) then forceUnsetSlots = false end
    for cat, items in pairs(self.provCats) do
        for itemRank, provs in pairs(items) do
            local slotQ = provs[chestID] ---@type slotQ
            if (slotQ) then self:removeProv(chestID, self:itemByRank(cat, itemRank), forceUnsetSlots) end
            -- provs[chestID] = nil
        end
    end
    if (forceUnsetSlots) then
        self.rmProvs[chestID] = nil
    end
    -- for cat, items in pairs(self.urgentProvCats) do for itemRank, provs in pairs(items) do provs[chestID] = nil end end
    -- self.rmProvs[chestID] = nil
    -- for slot in self:iterSlots(nil, nil, {sourceID = chestID}) do
    -- slot:setProv()
    -- slot:queueUrgentProvCheck()
    -- self.slotsNeedUnsetProvQ:push(slot)
    -- end
end

function Force:urgentCheckBestProvs(itemName, chestID)
    if (not itemName) or (not chestID) then return 0 end
    local itemInf = self:itemInfo(itemName)
    if (not itemInf) then return 0 end
    local slotLimit = gSets.maxSlotsCheckProvPerTick
    local item = itemInf
    local chest = TC.getObj(chestID)
    if (not chest) then return 0 end
    chestID = chest.id
    if (not self.urgentProvCats[itemInf.category]) or (not self.urgentProvCats[itemInf.category][itemInf.rank]) or
        (not self.urgentProvCats[itemInf.category][itemInf.rank][chestID]) then
        return 0
    end
    local slotQ = self.urgentProvCats[itemInf.category][itemInf.rank][chestID] ---@type slotQ
    if (not chest) then
        self.urgentProvCats[itemInf.category][itemInf.rank][chestID] = nil
        return 0
    end
    if (not slotQ) or (slotQ:size() <= 0) then return 0 end
    local abortProv = false
    local c = 0
    local fillLimit = gSets.itemFillSize()
    local lim = item.fillLimit or fillLimit
    if (not chest) then return 0 end
    if (chest:itemAmt(item.name) < lim) then return slotQ:size() end
    for slot in slotQ:slotIter(slotLimit, true) do
        c = c + 1
        local fillLimit = slot:fillLimit()
        if (slot:itemIsBetterOrCloser(item.name, chest)) then
            slot:setProv(chest, item.name)
            local needsRet = slot:needsReturn()
            local slotStack = slot:itemStack()
            if (needsRet) then
                self.slotsNeedReturnQ:push(slot, true)
                chest:cacheRemove(item.name, fillLimit)
            elseif (slotStack.count <= 0) then
                chest:cacheRemove(item.name, fillLimit)
            else
                chest:cacheRemove(item.name, fillLimit - slotStack.count)
            end
        end
        if (chest:itemAmt(item.name) < fillLimit) then break end
    end
    return slotQ:size()
end

function Force:tickCheckBestRmProvs()
    local slotsPerTick = gSets.chestRmSlotsCheckedPerTick
    local highestID = DB.getHighest(SL.dbName)
    local c = 0
    for chestID, items in pairs(self.rmProvs) do
        for itemName, curSlotID in pairs(items) do
            ---@type slotIterFilter
            local opts = {
                nonMatchReturnID = true
            }
            opts.sourceID = chestID
            opts.filter = itemName
            for slot in self:iterSlots(nil, curSlotID, opts) do
                if (c >= slotsPerTick) then return end
                if (type(slot) == "number") then
                    items[itemName] = slot + 1
                    -- c = c + 1
                else
                    -- local sourceID = slot:sourceID()
                    -- local filterItem = slot:filterItem()
                    -- if (sourceID) and (filterItem) and (sourceID == chestID) and (filterItem == itemName) then
                    slot:setProv()
                    slot:queueUrgentProvCheck()
                    -- end
                    items[itemName] = slot.id + 1
                    c = c + 1
                end
                if (items[itemName] > highestID) then
                    items[itemName] = nil
                    break
                end
            end
        end
    end
end

function Force:tickCheckBestProvs3()
    local urgCheckBest = self.urgentCheckBestProvs
    local getChest = TC.getObj
    local slotLimit = gSets.maxSlotsCheckProvPerTick
    local highest = DB.highest(SL.dbName)
    local fillLimit = gSets.itemFillSize()
    local doUpgrade = self:doUpgrade()
    local doReturn = self:doReturn()
    local c = 0
    local getSlotObj = SL.getObj
    -- cInform('tickCheckBestProvs3------------')
    for cat, provItems in pairs(self.provCats) do
        -- cInform(cat)
        for rank, provs in pairs(provItems) do
            -- cInform(rank)
            local item = self:itemByRank(cat, rank)
            if (item) then
                for provID, curSlotID in pairs(provs) do
                    -- cInform('provID: '..provID..', curSlotID: '..curSlotID)
                    local chest = getChest(provID)
                    if (not chest) then
                        self:removeProvID(provID, true)
                    else
                        local urgentRemain = urgCheckBest(self, item.name, provID)
                        local abortProv = false
                        local prov = chest
                        local lim = item.fillLimit or fillLimit
                        local ammoMin = 1
                        if (prov:itemAmt(item.name) >= ammoMin) and (urgentRemain <= 0) and (provs[provID]) and
                            (provs[provID] <= highest) then
                            for slot in self:iterSlots(nil, curSlotID, {
                                category = cat,
                                isBetterOrCloser = {
                                    chest = prov,
                                    item = item.name
                                },
                                insideArea = chest._area,
                                nonMatchReturnID = true
                            }) do
                                if (type(slot) == "number") then
                                    -- cInform('slotID: '..slot)
                                    if (getSlotObj(slot)) then
                                        c = c + 1
                                    end
                                    provs[provID] = slot + 1
                                else
                                    -- cInform('slotID: '..slot.id)
                                    local fillLimit = slot:fillLimit()
                                    slot:setProv(prov, item.name)
                                    local needsRet = slot:needsReturn()
                                    local slotStack = slot:itemStack()
                                    if (needsRet) then
                                        self.slotsNeedReturnQ:push(slot, true)
                                        prov:cacheRemove(item.name, fillLimit)
                                    elseif (slotStack.count <= 0) then
                                        prov:cacheRemove(item.name, fillLimit)
                                    else
                                        prov:cacheRemove(item.name, fillLimit - slotStack.count)
                                    end
                                    provs[provID] = slot.id + 1
                                    c = c + 1
                                end
                                if (c >= slotLimit) then break end
                                if (prov:itemAmt(item.name) < ammoMin) or (provs[provID] > highest) then break end
                                -- if (prov:itemAmt(item.name) < fillLimit) or (provs[provID] > highest) or (c >= slotLimit) then break end
                            end
                            -- if (provs[provID] > highest) then
                            -- break
                            -- provs[provID] = nil
                            -- end
                            -- if (c >= slotLimit) then
                            --     return
                            -- end
                        else
                            -- cInform('urgentRemain: ', urgentRemain)
                            -- cInform('failed to get into main checkBestProv loop')
                            -- cInform('itemAmt: ', prov:itemAmt(item.name), ', urgentRemain: ', urgentRemain, ', provs[provID]: ', provs[provID])
                        end
                    end
                end
            end
        end
    end
    -- cInform('------------')
end

---@param slot Slot
---@param item string
---@return boolean
function Force:entFiltersAllow(slot, item)
    local filters = self.entFilters
    local slotName = slot:entName()
    for i = 1, #filters do
        local filter = filters[i]
        if (filter.ent == slotName) then
            if (filter.mode == util.FilterModes.whitelist) then
                if (not table.containsValue(filter.filters, item)) then return false end
            else
                if (table.containsValue(filter.filters, item)) then return false end
            end
            return true
        end
    end
    return true
end

return Force
