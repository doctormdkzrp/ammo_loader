---@class DB
DB = {}
DB.registeredNames = {}

function DB.register(name) DB.registeredNames[name] = true end

function DB._init()
    storage["DB"] = {}
    -- storage["DBidCounters"] = {}
    for name, t in pairs(DB.registeredNames) do DB.new(name) end
    return nil
end
-- Init.registerFunc(DB._init)

function DB.master() return storage["DB"] end

DB.deletedLimit = 10000

function DB.new(name)
    local mas = DB.master()
    if mas[name] ~= nil then return mas[name] end

    mas[name] = {amtDeleted = 0, nextID = 1, idCache = {}}
    return mas[name]
end

function DB.getDB(name)
    local mas = DB.master()
    local db = mas[name]
    if not db then return DB.new(name) end
    return db
end
-- DB.getOrCreate = function(name)
--     local mas = DB.master()
--     local db = mas[name]
--     if not db then
--         return DB.new(name)
--     end
--     return db
-- end

function DB.getEntries(name)
    if (not storage.DB) then return {} end
    local db = storage["DB"][name]
    if not db then
        db = {amtDeleted = 0, nextID = 1, idCache = {}}
        storage["DB"][name] = db
    end
    return db.idCache
end

function DB.iter(name, limit, startID)
    local idCache = DB.getEntries(name)
    startID = startID or 1
    local id = startID
    limit = limit or (DB.highest(name) - (startID - 1))
    local c = 0
    local function iter()
        c = c + 1
        if (c > limit) then return end
        local obj = idCache[id]
        -- while (c <= limit) and (obj ~= nil) do
            -- c = c + 1
        -- end
        id = id + 1
        if (not obj) then return iter() end
        -- id, obj = next(idCache, id)
        -- if (not id) or (not obj) then return end
        if (obj.isValid ~= nil) and (not obj:isValid()) then
            obj:destroy()
            return iter()
        end
        return obj, c
    end
    return iter
end

function DB.getHighest(name) return DB.getDB(name).nextID - 1 end
DB.highest = DB.getHighest

function DB.reset(name)
    local mas = DB.master()
    mas[name] = nil
    mas[name] = DB.new(name)
end

---Insert an object into a database, giving it a permanent id.
---@param name string
---@param obj dbObject
---@return number
function DB.insert(name, obj)
    local db = DB.getDB(name)
    -- if not db then return false end
    -- if (type(obj) == "table") and (obj._type ~= nil) then --(obj._type=="TrackedChest")
    -- end
    -- local existingID = DB.getID(name, obj)
    -- if (existingID ~= nil) then return existingID end
    local ind = db.nextID
    db.nextID = db.nextID + 1

    db.idCache[ind] = obj
    return ind
end

---@return dbObject | nil
function DB.getObj(name, id, bypassValidCheck)
    local idCache = storage.DB[name].idCache
    local obj = idCache[id]
    -- if (not objs) then
    --     return nil
    -- end
    -- local obj = objs[id]
    if (not obj) or (obj._destroying) then
        return nil
    elseif (bypassValidCheck) then
        return obj
    end
    if (not obj:isValid()) then
        cInform("obj ", id, " in DB ", name, " invalid. Destroying...")
        obj:destroy()
        return nil
    end
    return obj
end

function DB.getObjsFromEnt(dbName, ent)
    if (not dbName) or (not ent) or (not ent.valid) then return {} end
    local objs = DB.getEntries(dbName)
    local res = {}
    for i = 1, DB.highest(dbName) do
        local obj = objs[i]
        if (obj) and (obj.ent) and (obj.ent.valid) and (obj.ent == ent) then
            table.insert(res, obj)
        end
    end
    return res
end

function DB.getObjFromEnt(dbName, ent)
    local objs = DB.getObjsFromEnt(dbName, ent)
    if (objs) and (#objs > 0) then return objs[1] end
end

function DB.getAllObj(name, ids)
    result = {}
    for ind, id in pairs(ids) do table.insert(result, DB.getObj(name, id)) end
    return result
end

function DB.getID(name, obj)
    local db = DB.getDB(name)
    if not db then return nil end
    for id, item in pairs(db.idCache) do if (item == obj) then return id end end
    return nil
end

function DB.deleteID(name, id)
    local db = DB.getDB(name)
    if not db.idCache[id] then return nil end
    db.idCache[id] = nil
    -- db.amtDeleted = db.amtDeleted + 1
    -- if db.amtDeleted > DB.deletedLimit then
    --     version.update()
    -- end
end

DB.idCounter = {}
function DB.idCounter.counters() return storage["DBidCounters"] end
function DB.idCounter.new(name)
    if (DB.idCounter.counters()[name] == nil) then
        DB.idCounter.counters()[name] = 1
    end
end
function DB.idCounter.up(name)
    local counters = DB.idCounter.counters()
    if (counters[name] == nil) then DB.idCounter.new(name) end
    local curID = counters[name]
    counters[name] = curID + 1
    return curID
end
DB.idCounter.next = DB.idCounter.up
function DB.idCounter.last(name) return DB.idCounter.counters()[name] end

return DB
