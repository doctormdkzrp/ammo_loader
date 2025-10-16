Init = {}
Initializer = Init
Initializer.funcBackup = {}
Initializer.localBackup = {}
Init._resetFuncs = {}
Init.preInitFuncs = {}

-- Initializer.globals = {}
-- function Init.funcs()
--     return Init.initFuncs
-- end
-- function Init.localFuncs()
--     if storage["_initLocalFuncs"] == nil then
--         storage["_initLocalFuncs"] = Init.localBackup
--     end
--     return storage["_initLocalFuncs"]
-- end
function Init.resetFuncs() return Init._resetFuncs end

function Init.registerFunc(f)
    table.insert(Init.funcBackup, f)
    return f
end

Init.registerInitFunc = Init.registerFunc
function Init.registerOnLoadFunc(f)
    table.insert(Init.localBackup, f)
    return f
end

function Init.registerResetFunc(f)
    table.insert(Init._resetFuncs, f)
    return f
end

function Init.registerPreInitFunc(f)
    table.insert(Init.preInitFuncs, f)
    return f
end

---Initialize/Reset mod global table
---@param isGameInitEvent boolean
function Init.doInit(doPreInit)
    doPreInit = doPreInit or true
    cInform("Initializing")
    -- Init.reset()
    -- if (storage["DB"] ~= nil) then
    --     HI.destroyAll()
    -- end
    local initFuncs = Init.funcBackup
    if (not storage.persist) then storage.persist = {} end
    if (doPreInit) then
        -- serpLog("global persist before: ", storage.persist.chestFilters)
        for ind, func in pairs(Init.preInitFuncs) do func() end
        -- serpLog("global persist after: ", storage.persist.chestFilters)
        -- local trackedPlayers = storage["trackedPlayers"]
        -- for key, obj in pairs(global) do
        --     if (key ~= "persist") then storage[key] = nil end
        -- end
    end
    local persist = storage.persist
    -- serpLog("persist: ", persist)
    -- local persist = {}
    -- local trackedPlayers = storage["trackedPlayers"]
    -- for key, obj in pairs(global) do
    --     if (key ~= "persist") then storage[key] = nil end
    -- end
    storage = { persist = persist }
    gSets._init()
    -- serpLog("new storage.persist: ", storage.persist.chestFilters)
    -- if not gSets.enabled() then return end
    DB._init()
    ItemDB.__init()
    EntDB._init()
    createdQ._init()
    Force._init()
    for ind, func in pairs(initFuncs) do func() end
    cInform(#initFuncs .. " functions successfully executed.")
    -- if (trackedPlayers) then
    --     for playerInd, pos in pairs(trackedPlayers) do
    --         if not storage["trackedPlayers"][playerInd] then
    --             storage["trackedPlayers"][playerInd] = pos
    --         end
    --     end
    -- end
    if not gSets.enabled() then return end
    ctInform(
        "initializing global tables. This may take up to a few minutes. Lag spikes may occur during this time.")
    createdQ.startReset()
    -- checkAllEntities()
    createdQ.checkAllEntities()
    return true
end

function Init.doOnLoad()
    -- local localFuncs = Init.localBackup
    for ind, func in pairs(Init.localBackup) do func() end
end

return Init
