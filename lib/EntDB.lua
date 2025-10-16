EntDB = {}

EntDB.dbName = "EntDB"

EntDB.ammoTypes = {}
EntDB.ammoTypes["car"] = 1
EntDB.ammoTypes["ammo-turret"] = 1
EntDB.ammoTypes["artillery-wagon"] = 1
EntDB.ammoTypes["artillery-turret"] = 1
EntDB.ammoTypes["character"] = 1
EntDB.ammoTypes["spider-vehicle"] = 1

EntDB.typesCanMove = {}
EntDB.typesCanMove["character"] = true
EntDB.typesCanMove["car"] = true
EntDB.typesCanMove["artillery-wagon"] = true
EntDB.typesCanMove["locomotive"] = true
EntDB.typesCanMove["spider-vehicle"] = true

EntDB.globalBlacklist = {}
EntDB.globalBlacklist["vehicle-deployer"] = true
EntDB.globalBlacklist[protoNames.hiddenInserter] = true

EntDB.globalWhitelist = {}
EntDB.globalWhitelist["repair-turret"] = true

local chestNameList = {}
for ind, name in pairs(protoNames.chests) do
    table.insert(chestNameList, name)
end
EntDB.eventFilters = {
    character = {{filter='type', type='character'}},
    chests = {{filter='name', name=chestNameList}}
}

-- Init.registerFunc(
EntDB._init = function()
    storage["EntDB"] = {}
    -- storage["EntDB"]["ammoEnts"] = {}
    -- storage["EntDB"]["fuelEnts"] = {}
    -- storage["EntDB"]["turretAmmoCategories"] = {}
    -- storage["EntDB"]["carAmmoCategories"] = {}
    storage["EntDB"]["entCategories"] = {}
    storage.EntDB.fillLimits = {}
    storage.EntDB.entProtos = {}
    -- storage["EntDB"]["ents"] = EntDB.findEntNames()
    -- storage["EntDB"]["ents"] = {}
    -- storage["EntDB"]["ents"][protoNames.hiddenInserter] = nil
    -- storage["EntDB"]["tracked"] = {}
    -- storage["EntDB"]["hash"] = {}
    -- storage["EntDB"]["ammoEnts"] = {}
    -- storage["EntDB"]["fuelEnts"] = {}

    -- for name, proto in pairs(
    --     game.get_filtered_entity_prototypes(
    --         {{filter = "turret"}, {filter = "vehicle"}, {filter = "type", type = "character"}}
    --     )
    -- ) do
    --     if (proto.type ~= "car") or (proto.guns) then
    --         storage["EntDB"]["ammoEnts"][proto.name] = true
    --     end
    -- end
    for name, proto in pairs(prototypes.entity) do
        -- if (proto.burner_prototype) then
        --     storage["EntDB"]["fuelEnts"][proto.name] = true
        -- end
        local protoObj = EntDB.proto(name)
    end
end
-- )

function EntDB.ammoEnts() return storage["EntDB"]["ammoEnts"] end

function EntDB.fuelEnts() return storage["EntDB"]["fuelEnts"] end

function EntDB.entCategories() return storage["EntDB"]["entCategories"] end

function EntDB.entProtos() return storage.EntDB.entProtos end

function EntDB.proto(name)
    -- local protos = EntDB.entProtos()
    if (not name) then return end
    local protos = storage.EntDB.entProtos
    local proto = protos[name]
    if (proto) then return proto end
    local gameProto = prototypes.entity[name] ---@type LuaEntityPrototype
    if (not gameProto) then
        cInform("EntDB.proto: no entity prototype by that name")
        return
    end
    if ((TC.isChestName(name)) or (SL.entProtoIsTrackable(gameProto))) then
        proto = {}
        local gameProtoType = gameProto.type
        local gameProtoTypeUnderscore = string.gsub(gameProtoType, "%-", "_")
        gameProtoTypeUnderscore = gameProtoTypeUnderscore.."_gui"
        cInform(gameProtoTypeUnderscore)
        if (defines.relative_gui_type[gameProtoTypeUnderscore]) then
            cInform("entDB: relative gui type found in defines.relative_gui_type")
            proto.relativeGuiType = defines.relative_gui_type[gameProtoTypeUnderscore]
        elseif (alGui.relativeGuiTypes[gameProtoType]) then
            cInform("entDB: relative gui type found in alGui.relativeGuiTypes")
            proto.relativeGuiType = alGui.relativeGuiTypes[gameProtoType]
        elseif (gameProto.burner_prototype) then
            cInform("entDB: relative gui type found using burner")
            proto.relativeGuiType = alGui.relativeGuiTypes.burner
        end
        protos[name] = proto
    end
    return protos[name]
end

function EntDB.invProto(name, invInd)
    local proto = EntDB.proto(name)
    local invProtos = proto.invProtos
    if not invProtos then
        invProtos = {}
        proto.invProtos = invProtos
    end
    local invProto = invProtos[invInd]
    if not invProto then
        invProto = {}
        invProtos[invInd] = invProto
    end
    return invProto
end

function EntDB.slotProto(name, invInd, slotInd)
    local invProto = EntDB.invProto(name, invInd)
    local slotProto = invProto[slotInd]
    if (not slotProto) then
        slotProto = {
            categories = {},
            categoryHash = {}
        }
        invProto[slotInd] = slotProto
    end
    return slotProto
end

function EntDB.fillLimits() return storage["EntDB"]["fillLimits"] end

function EntDB.getCategories(ent, invInd, slotInd)
    if (not ent) or (not ent.valid) or (not invInd) or (not slotInd) then return {} end
    local entObj = EntDB.entCategories()[ent.name]
    if (not entObj) then
        entObj = {}
        EntDB.entCategories()[ent.name] = entObj
    end
    local invObj = entObj[invInd]
    if (not invObj) then
        invObj = {}
        entObj[invInd] = invObj
    end
    local cats = invObj[slotInd]
    local type = "ammo"
    if (not cats) then
        local inv = ent.get_inventory(invInd)
        if (not inv) or (not inv.valid) then return {} end
        local slot = inv[slotInd]
        if (not slot) or (not slot.valid) then return {} end
        cats = EntDB.getSlotCategory(slot)
        if (cats) and (#cats > 0) then
            invObj[slotInd] = cats
            return cats
        end
    else
        return cats
    end
end

function EntDB.getCategory(ent, invInd, slotInd)
    local cats = EntDB.getCategories(ent, invInd, slotInd)
    if (cats) and (#cats > 0) then return cats[1] end
end

--- Test a LuaItemStack against all items to find its ammo/fuel category
--- @param itemSlot LuaItemStack
function EntDB.getSlotCategories(itemSlot)
    local canInsert = itemSlot.can_set_stack
    if (canInsert({
        name = "iron-plate",
        count = 1
    })) then return nil end
    local cats = {}
    local type = "ammo"
    for name, ranks in pairs(ItemDB.cats()) do
        local item = itemInfo(ranks[1])
        if (item) and (canInsert({
            name = item.name,
            count = 1
        })) then
            -- if (canInsert({name = name, count = 1})) then
            -- if (item.category == "artillery-shell") then
            -- cInform("get cat artillery shell")
            -- end
            table.insert(cats, item.category)
            type = item.type
            -- return info.category, info.type
        end
    end
    return cats, type
end

--- Test a LuaItemStack against all items to find its ammo/fuel category
--- @param itemSlot LuaItemStack
function EntDB.getSlotCatAndType(ent, invInd, slotInd)
    if (not isValid(ent)) or (not invInd) or (not slotInd) then return end
    local slotInfo = nil
    local entProto = storage.EntDB.entProtos[ent.name]
    if (entProto) and (entProto.invProtos) and (entProto.invProtos[invInd]) then
        local invProto = entProto.invProtos[invInd]
        if (invProto) and (invProto.slotProtos) and (invProto.slotProtos[slotInd]) then
            slotInfo = invProto.slotProtos[slotInd]
        end
    end
    if (slotInfo) and (slotInfo.category) and (slotInfo.type) then return slotInfo.category, slotInfo.type end
    local inv = nil
    if (invInd == "burner") then
        if (isValid(ent.burner)) then inv = ent.burner.inventory end
    else
        inv = ent.get_inventory(invInd)
    end
    if (not isValid(inv)) or (#inv < slotInd) then return end
    local itemSlot = inv[slotInd]
    local canInsert = itemSlot.can_set_stack
    if (canInsert({
        name = "iron-plate",
        count = 1
    })) then return nil end
    -- local cats = {}
    local cat = nil
    local type = nil
    for name, ranks in pairs(ItemDB.cats()) do
        local item = itemInfo(ranks[1])
        if (item) and (canInsert({
            name = item.name,
            count = 1
        })) then
            -- if (canInsert({name = name, count = 1})) then
            -- if (item.category == "artillery-shell") then
            -- cInform("get cat artillery shell")
            -- end
            -- table.insert(cats, item.category)
            if (not slotInfo) then slotInfo = EntDB.slotProto(ent.name, invInd, slotInd) end
            if (not table.containsValue(slotInfo.categories, item.category)) then
                slotInfo.category = item.category
                slotInfo.type = item.type
                if (slotInfo.categoryHash == nil) then slotInfo.categoryHash = {} end
                table.insert(slotInfo.categories, item.category)
                slotInfo.categoryHash[item.category] = true
            end
            -- return item.category, item.type
            -- return info.category, info.type
        end
    end
    if (slotInfo) and (slotInfo.category) and (slotInfo.categories) and (slotInfo.type) then
        return slotInfo.category, slotInfo.type, slotInfo.categories
    end
end

---Get names of all LuaEntities that are trackable as Slots. Is in hash form.
-- function EntDB.names() return storage.EntDB.ents end
-- EntDB.protoNames = EntDB.names

-- function EntDB.entHash() return storage["EntDB"]["hash"] end

-- function EntDB.contains(name)
--     if (storage["EntDB"].ents[name]) then return true end
--     return false
-- end

-- function EntDB.findEntNames(class)
--     local res = {}
--     local protos = prototypes.entity
--     local count = 0
--     for name, proto in pairs(protos) do
--         if (not class or class == TC.className) and (TC.isChestName(name)) then res[name] = true end
--         local burnerProto = proto.burner_prototype
--         if ((not class) or (class == SL.className)) and ((burnerProto) and (burnerProto.fuel_inventory_size > 0)) or
--             ((proto.guns) or (proto.automated_ammo_count) or (EntDB.ammoTypes[proto.type])) then
--             count = count + 1
--             res[proto.name] = true
--         end
--     end
--     return res
-- end

function EntDB.isTrackableEnt(ent)
    if (not isValid(ent)) then return false end
    -- if (type(ent) == "table") then ent = ent.name end
    if (EntDB.isTrackableName(ent.name)) then return true end
    return false
end

function EntDB.isTrackableName(entName)
    if (EntDB.globalBlacklist[entName]) then return false end
    if (EntDB.globalWhitelist[entName]) then return true end
    if (storage.EntDB.entProtos[entName]) then return true end
    return false
end

function EntDB.tracked() return storage.EntDB.tracked end

function EntDB.addTracked(obj, ent)
    ent = ent or obj.ent
    local id = EntDB.entID(ent)
    local list = storage.EntDB.tracked[id]
    if (not list) then
        list = {}
        storage.EntDB.tracked[id] = list
    end
    -- local dbList = list[obj.dbName]
    -- if (not dbList) then
    --     dbList = {}
    --     list[obj.dbName] = dbList
    -- end
    table.insert(list, {
        dbName = obj.dbName,
        id = obj.id
    })
end

function EntDB.iterTracked(ent, dbName)
    local tracked = EntDB.tracked()
    local id = EntDB.entID(ent)
    local list = tracked[id] or {}
    local key, info
    local function iter()
        key, info = next(list, key)
        if (not key) then return end
        if (dbName) and (info.dbName ~= dbName) then return iter() end
        local obj = DB.getObj(info.dbName, info.id)
        if (not obj) then
            list[key] = nil
            if (Map.size(list) <= 0) then
                tracked[id] = nil
                return
            end
            return iter()
        end
        if (obj.ent == ent) then return obj end
        return iter()
    end
    return iter
end

---@return fun():Slot
function EntDB.iterTrackedSlots(ent) return EntDB.iterTracked(ent, SL.dbName) end

---@return fun():HiddenInserter
function EntDB.iterTrackedInserters(ent) return EntDB.iterTracked(ent, HI.dbName) end

function EntDB.trackedCount(ent, dbName)
    local c = 0
    for obj in EntDB.iterTracked(ent, dbName) do c = c + 1 end
    return c
end

function EntDB.entID(ent)
    if (not isValid(ent)) then return "" end
    local id = ""
    id = id .. ent.name
    id = id .. ent.force.name
    id = id .. ent.surface.name
    if (not SL.entCanMove(ent)) then
        local pos = ent.position
        -- id = id .. math.floor(pos.x)
        -- id = id .. math.floor(pos.y)
        id = id .. pos.x
        id = id .. pos.y
    end
    return id
end

function EntDB.purgeTracked()
    local tracked = EntDB.tracked()
    for entID, list in pairs(tracked) do
        for key, info in pairs(list) do
            local obj = DB.getObj(info.dbName, info.id)
            if (not obj) then list[key] = nil end
        end
        if (Map.size(list) <= 0) then tracked[entID] = nil end
    end
end

---@return table<int, string>
function EntDB.allNames()
    if (storage.EntDB) then
        if (storage.EntDB.allNames) then return storage.EntDB.allNames end
    else
        storage.EntDB = {}
    end
    local names = {}
    -- local chestNames = protoNames.chests
    -- names = table.join(names, chestNames)
    local protos = {}
    table.insert(names, "repair-turret")
    for name, proto in pairs(prototypes.entity) do
        -- if (not proto.type == "boiler") then
        if (proto.burner_prototype) or (proto.automated_ammo_count) or (proto.type == "character") or (proto.guns) then
            if (proto.name ~= HI.protoName) then
                table.insert(protos, proto)
                table.insert(names, proto.name)
            end
        end
        -- end
    end
    storage.EntDB.allNames = names
    return storage.EntDB.allNames
end

function EntDB.allNamesWithChests()
    if (storage.EntDB) then
        if (storage.EntDB.allNamesWithChests) then return storage.EntDB.allNamesWithChests end
    else
        storage.EntDB = {}
    end
    local allNames = table.deepcopy(EntDB.allNames())
    for ind, name in pairs(protoNames.chests) do
        table.insert(allNames, name)
    end
    storage.EntDB.allNamesWithChests = allNames
    return allNames
end

function EntDB.EntNamesFilters()
    if (storage.EntDB) then
        if (storage.EntDB.entNamesFilters) then
            cInform('name filters cached...')
            return storage.EntDB.entNamesFilters
        end
    else
        storage.EntDB = {}
    end
    local names = EntDB.allNames()
    -- local filters = util.namesFilter(names)
    local filters = {{filter='name', name=names}}
    storage.EntDB.entNamesFilters = filters
    return filters
end

function EntDB.entNamesFiltersWithChests()
    if (storage.EntDB) then
        if (storage.EntDB.entNamesFiltersWithChests) then
            cInform('name filters with chests cached...')
            return storage.EntDB.entNamesFiltersWithChests
        end
    else
        storage.EntDB = {}
    end
    local names = EntDB.allNamesWithChests()
    -- local filters = util.namesFilter(names)
    local filters = {{filter='name', name=names}}
    storage.EntDB.entNamesFiltersWithChests = filters
    return filters
end

return EntDB
