-- ternary operator: (condition and {ifTrue} or {ifFalse})[1]

require "stdlib/string"
Map = require "stdlib/Map"
Array = require "stdlib/Array"
require "stdlib/Queue"
require "stdlib/area/area"
require "stdlib/area/position"

---Module containing many utility functions.
util = {}

---Shortcut for some commonly used colors with the desired alpha already set.
util.colors = {}
util.colors.alpha = 0.1
local alpha = util.colors.alpha
util.colors.red = { r = 1, g = 0, b = 0, a = alpha }
util.colors.blue = { r = 0, g = 0, b = 1, a = alpha }
util.colors.green = { r = 0, g = 1, b = 0, a = alpha }
util.colors.purple = { r = 0.5, g = 0, b = 0.5, a = alpha }
util.colors.fuchsia = { r = 1, g = 0, b = 1, a = alpha }
util.colors.litePurple = { r = 0, g = 0.08, b = 0.08, a = alpha }
util.colors.teal = { r = 0, g = 0.5, b = 0.5, a = alpha }
util.colors.slotWithProviderColor = { r = 0.8, g = 0.8, b = 0, a = 0.5 }
util.colors.chestRangeColor = { r = 0.15, g = 0.04, b = 0.04, a = 0.1 }

util.FilterModes = {
    whitelist = 'whitelist', ---@type alFilterMode
    blacklist = 'blacklist' ---@type alFilterMode
}

function util.isValid(gameObj)
    if (not gameObj) or (not gameObj.valid) then return false end
    return true
end

isValid = util.isValid

---Check if LuaItemStack is nil or valid_for_read is false
---@param stack LuaItemStack
function util.readyForRead(stack)
    if (stack) and (stack.valid_for_read) then return true end
    return false
end

--Check if any object is either nil or empty.
--@param var any
-- function util.isEmpty(var)
--     if (var == nil) then return true end
--     local t = type(var)
--     if (t == "string") and (var == "" or var == "0" or var == "nil") then
--         return true
--     elseif (t == "boolean") and (var == false) then
--         return true
--     elseif (t == "number") and (t == 0) then
--         return true
--     elseif (t == "userdata") then
--         if (var.valid ~= nil) and (var.valid == false) then
--             return true
--         elseif (var.valid_for_read ~= nil) and ((var.valid_for_read == false) or (var.count <= 0)) then
--             return true
--         elseif (var.count ~= nil) and (var.count <= 0) then
--             return true
--         elseif (next(var) == nil) then
--             return true
--         end
--     end
--     return false
-- end

---Check if object is a table with no values.
---@param t table|nil
---@return boolean
function util.tableIsEmpty(t)
    if (not t) or (type(t) ~= "table") or (not next(t)) then return true end
    return false
end

table.isEmpty = util.tableIsEmpty
-- table.isEmpty = function(t)
--     if (not t) or (table_size(t)<=0) then return true end
--     return false
-- end

---True if all keys and values in tables are the same
---@param tbl1 table
---@param tbl2 table
---@return boolean
function util.tableEquals(tbl1, tbl2)
    if tbl1 == tbl2 then return true end
    if (not tbl1) or (not tbl2) then return false end
    for k, v in pairs(tbl1) do
        if type(v) == "table" and type(tbl2[k]) == "table" then
            if not util.tableEquals(v, tbl2[k]) then return false end
        else
            if (v ~= tbl2[k]) then return false end
        end
    end
    for k, v in pairs(tbl2) do if tbl1[k] == nil then return false end end
    return true
end

table.equals = util.tableEquals

---Check an object to see if it is an empty LuaItemStack or SimpleItemStack.
---@param stack LuaItemStack | ItemStack
---@return boolean
function util.stackIsEmpty(stack)
    if (not stack) then return true end
    if (type(stack) == "userdata") then
        if (stack.valid and stack.valid_for_read) then
            if (stack.count > 0) then return false end
        end
        return true
    end
    if (type(stack) == "table") then
        if (stack.count and stack.count > 0) then
            return false
        end
        return true
    end
    return true
end

---Print to console if debugging is enabled.
---@param s string
---@param forceShow boolean | nil
function util.inform(s, forceShow)
    if (not game) then
        -- error("called inform when game was invalid:\n" .. debug.traceback())
        return nil
    end
    local debug = true
    if (gSets) and (gSets.cache()) then debug = gSets.debug() end
    if (not debug) and (not forceShow) then return false end
    local str = string.toString(s)
    game.print("[Ammo-Loader]:> " .. str)
end

inform = util.inform

---Concatenate all args and print the result.
function util.cInform(...)
    if (not gSets.debugging()) then return nil end
    return util.inform(string.concat(...))
end

cInform = util.cInform

---Concatenate all args and print the result. Will print even if debugging is disabled.
function util.ctInform(...)
    if (not gSets.debugImportant()) then return end
    return util.inform(string.concat(...), true)
end

ctInform = util.ctInform

function util.serpInform(val)
    if (not gSets.debugging()) then return nil end
    return util.inform(serpent.block(val))
end

serpInform = util.serpInform

---Print a profiler's value to the console.
---@param prof LuaProfiler
---@param msg string
function util.printProfiler(prof, msg)
    if (gSets.debugging()) then
        cInform("Profiler: ", msg)
        game.print(prof)
    end
end

printProfiler = util.printProfiler

---Alias for game.surfaces.nauvis.find_entities_filtered
---@param options table
---@return LuaEntity[]
function util.nauvisFind(options)
    local res = game.surfaces.nauvis.find_entities_filtered(options)
    return res
end

util.nFind = util.nauvisFind

---Find entities on all surfaces.
---@param options table
---@return LuaEntity[]
function util.allFind(options)
    local results = {}
    for id, surf in pairs(game.surfaces) do
        local find = surf.find_entities_filtered(options)
        results = Array.merge(results, find)
    end
    return results
end

---Drop items on a surface.
---@param opts table
function util.spillItemStack(opts)
    ---@type LuaItemStack
    local stack = opts.stack
    ---@type LuaForce
    local force = opts.force
    ---@type LuaSurface
    local surf = opts.surface
    ---@type Position
    local pos = opts.position

    if (util.stackIsEmpty(stack)) then return end
    surf = surf or game.get_surface("nauvis")
    pos = pos or { x = 0, y = 0 }
    surf.spill_item_stack(pos, stack, true, force, false)
end

util.spillStack = util.spillItemStack

---Destroy all entities with a given name.
---@param name string
function util.destroyAll(name)
    local found = util.allFind({ name = name })
    for i = 1, #found do found[i].destroy() end
end

---Check if a Slot is in range of a Chest.
---@param slot Slot
---@param chest Chest
function util.isInRange(slot, chest)
    local rad = gSets.chestRadius()
    
    -- Use surface.index for comparison - more reliable than surface.name
    local slotSurfIdx = slot:surfaceIndex()
    local chestSurfIdx = chest:surfaceIndex()
    
    if (rad <= 0) then
        -- Infinite range mode
        -- Same surface index is always allowed
        if slotSurfIdx == chestSurfIdx then
            return true
        end
        
        -- Check cross-surface setting for different surfaces
        if gSets.refs[protoNames.settings.crossSurfaces] then
            return true
        end
        
        return false
    end
    
    -- Limited range mode - must be on same surface
    if slotSurfIdx ~= chestSurfIdx then
        return false
    end
    
    -- Check if within range area
    local slotPos = slot:position()
    local area = Position.expand_to_area(chest:position(), rad)
    if (Area.inside(area, slotPos)) then return true end
    return false
end

---Destroy all renders belonging to a player. Returns true if any renders were destroyed.
---@param player LuaPlayer
function util.clearPlayerRenders(player, destroyNow)
    local didClear = false
    local renderObjs = rendering.get_all_objects("ammo-loader")
    for i, obj in pairs(renderObjs) do
        if (not obj.players) or (Array.contains(obj.players, player)) then
            -- rendering.set_visible(id, false)
            if (destroyNow) then
                obj.destroy()
            else
                alGui.rendersNeedDestroy()[obj.id] = 1
            end
            didClear = true
        end
    end
    return didClear
end

---Destroy all renders belonging to the mod.
function util.clearRenders() rendering.clear("ammo-loader") end

function util.empty(val)
    local type = type
    local t = type(val)
    if (t == "nil") then
        return true
    elseif (t == "number") and (val <= 0) then
        return true
    elseif (t == "string") and (val == "") then
        return true
    elseif (t == "table") then
        local next = next
        if (next(val) == nil) then
            return true
        elseif (val["isEmpty"]) and (type(val["isEmpty"]) == "function") and (val:isEmpty()) then
            return true
        elseif (val["isValid"]) and (type(val["isValid"]) == "function") and (not val:isValid()) then
            return true
        end
    elseif (t == 'userdata') then
        if (not val.valid) then return true end
        if (val.valid_for_read) then
            if (val.count > 0) then return false end
        end
        return false
    end
    return false
end

empty = util.empty

function util.isPositive(val)
    if (type(val) ~= "number") then return false end
    if (val <= 0) then return false end
    return true
end

isPositive = util.isPositive

function util.hashToArray(hash) end

-- function util.startProfiler() if (gSets.canUseProfiler()) then Profiler.Start() end end

-- function util.stopProfiler() Profiler.Stop() end

function util.memoize(f)
    local mem = {}                       -- memoizing table
    setmetatable(mem, { __mode = "kv" }) -- make it weak
    return function(x)                   -- new version of ’f’, with memoizing
        local r = mem[x]
        if r == nil then                 -- no previous result?
            r = f(x)                     -- calls original function
            mem[x] = r                   -- store result for reuse
        end
        return r
    end
end

function util.serpLog(...)
    if (gSets.debugging()) then
        local args = table.pack(...)
        local res = ""
        local resTab = { "" }
        for i = 1, #args do
            local curArg = args[i]
            if (curArg) then
                if (type(curArg) == "string") then
                    res = res .. curArg
                    table.insert(resTab, curArg)
                elseif (type(curArg) == "userdata") and (curArg.valid) then
                    res = res .. serpent.block(curArg)
                    table.insert(resTab, curArg)
                elseif (type(curArg) == "table") then
                    res = res .. serpent.block(curArg)
                    table.insert(resTab, serpent.block(curArg))
                else
                    res = res .. serpent.block(curArg)
                    table.insert(resTab, serpent.block(curArg))
                end
            end
        end
        log(resTab)
    end
end

serpLog = util.serpLog

function util.getPlayer(p)
    if (not p) then return end
    if (type(p) == "number") then p = game.get_player(p) end
    if (not isValid(p)) then return end
    return p
end

---@return LuaPlayer
function util.eventPlayer(event)
    if (not event) or (not event.player_index) then return end
    return util.getPlayer(event.player_index)
end

function util.reversedEvents()
    if (not storage.definesReverse) or (not storage.definesReverse.events) then
        storage.definesReverse = { events = {} }
        for name, id in pairs(defines.events) do
            storage.definesReverse.events[id] = name
            -- if (id == eName) then
            --     return name
            -- end
        end
    end
    return storage.definesReverse.events
end

---@return string
function util.eventName(event)
    if (not event) then return end
    if (event.input_name) then return event.input_name end
    if (not event.name) then return end
    local revEvents = util.reversedEvents()
    local eName = event.name
    if (revEvents[eName]) then return revEvents[eName] end
    return nil
end

---@param var1 boolean
---@param var2 boolean
---@return boolean @***return true if var1 and var2 are opposite boolean values***
function util.notBoth(var1, var2)
    if (var1 and not var2) or (not var1 and var2) then return true end
    return false
end

function util.capitalize(str)
    str = string.gsub(str, "^%w", function(a, b)
        if (not b) then return string.upper(a) end
        return a .. string.upper(b)
    end)
    str = string.gsub(str, "%W%w", function(a, b)
        if (not b) then return string.upper(a) end
        return a .. string.upper(b)
    end)
    return str
end

string.capitalize = util.capitalize

function util.renderAddPlayer(renderID, player)
    local obj = renderID
    if (type(renderID) == "number") then
        obj = rendering.get_object_by_id(renderID)
    end
    if (not obj) then return false end
    local players = obj.players or {}
    table.insert(players, player)
    obj.players = players
    obj.visible = true
end

---@param renderID number | LuaRenderObject
---@param player LuaPlayer
---@param destroyIfNoPlayers boolean
---@return boolean @***True if renderID was destroyed, otherwise false.***
function util.renderRemovePlayer(renderID, player, destroyIfNoPlayers)
    local obj = renderID
    if (type(renderID) == "number") then
        obj = rendering.get_object_by_id(renderID)
    end
    if (not obj) then return false end
    if (not obj.players) then
        if (destroyIfNoPlayers) then
            obj:destroy()
            return true
        end
        return false
    end
    obj.players = Array.remove(obj.players, player)
    if (destroyIfNoPlayers) and (not obj.players or #obj.players <= 0) then
        obj:destroy()
        return true
    end
    return false
end

---@param renderID number
---@return boolean
function util.renderIsValid(renderID)
    if (type(renderID) == "number") and (rendering.get_object_by_id(renderID)) then return true end
    return false
end

---@param renderID number
---@return boolean @***True if the renderID was destroyed or invalid, otherwise false.***
function util.renderDestroyIfNoPlayers(renderID)
    if (not util.renderIsValid(renderID)) then return true end
    if (not rendering.get_players(renderID)) then
        rendering.get_object_by_id(renderID).destroy()
        return true
    end
    return false
end

function util.renderHasPlayer(renderID, player)
    local obj = rendering.get_object_by_id(renderID)
    if (not obj) or (not isValid(player)) then return false end
    local players = obj.players
    if (players) and (Array.contains(players, player)) then return true end
    return false
end

---@return boolean True if renderID was destroyed.
function util.renderTogglePlayer(renderID, player, destroyIfNoPlayers)
    if (not util.renderIsValid(renderID)) or (not isValid(player)) then return false end
    if (util.renderHasPlayer(renderID, player)) then
        return util.renderRemovePlayer(renderID, player, destroyIfNoPlayers)
    else
        util.renderAddPlayer(renderID, player)
    end
    return false
end

function util.commaValue(amount)
    if (not amount) then return "" end
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if (k == 0) then break end
    end
    return formatted
end

function util.pairsIter(tbl)
    local ind
    local fun
    fun = function()
        local val = next(tbl, ind)
        ind = ind or 0
        ind = ind + 1
        return val
    end
    return fun
end

function util.count(tbl)
    local c = 0
    for key, val in pairs(tbl) do c = c + 1 end
    return c
end

-- table.count = util.count
table.count = table_size

function util.getIndent(level)
    local base = "  "
    local res = ""
    for i = 1, level do res = res .. base end
    return res
end

function util.startProf(profiler)
    serpLog("--------------profiler start---------")
    util.profilers = { children = {}, parent = nil, profiler = game.create_profiler(), curLv = 0, textLines = {} }
    util.lineProf = game.create_profiler()
    debug.sethook(function(hookType)
        local profs = util.profilers
        if (hookType == "call") then
            local dbInf = debug.getinfo(2)
            local what = dbInf.what
            local newProfs = {
                profiler = game.create_profiler(),
                children = {},
                textLines = {},
                parent = profs,
                curLv =
                    profs.curLv + 1
            }
            table.insert(profs.children, newProfs)
            util.profilers = newProfs
        elseif (hookType == "tail call") then
            local dbInf = debug.getinfo(2)
            local what = dbInf.what
        elseif (hookType == "return") then
            local dbInf = debug.getinfo(2)
            local what = dbInf.what
            profs.profiler.stop()
            profs.textLines = {
                "\n", util.getIndent(profs.curLv), "Lv ", profs.curLv, "(", dbInf.nups, ")", ": ", dbInf.short_src, "~",
                dbInf.linedefined, "::", dbInf.name,
                " >> ", profs.profiler
            }
            if (profs.parent) then
                util.profilers = profs.parent
            else
                profs.profiler.reset()
            end
        elseif (hookType == "line") then
            local dbInf = debug.getinfo(2)
            local newProf = game.create_profiler(true)
            newProf.add(util.lineProf)
            local lines = {
                "\n", util.getIndent(profs.curLv), "Lv ", profs.curLv, "(", dbInf.nups, ")", ": ", dbInf.short_src, "~",
                dbInf.currentline, "::__line__",
                " >> ", newProf
            }
            profs.textLines = Array.merge(profs.textLines, lines)
            util.lineProf.reset()
        end
    end, "crl")
end

util.profilers = {}
util.curLv = 0

function util.stopProf(prof)
    debug.sethook()
    local topProf = util.profilers
    while (topProf.parent) do topProf = topProf.parent end
    local resTab = { "" }
    local curResTab = resTab
    local function getLogTable(prof)
        if (prof.textLines) then
            for i = 1, #prof.textLines do
                local numLines = #curResTab
                if numLines >= 19 then    -- Localised string can only have up to 20 parameters
                    local newStr = { "" } -- So nest them!
                    curResTab[numLines + 1] = newStr
                    curResTab = newStr
                end
                table.insert(curResTab, prof.textLines[i])
            end
        end
        for i = 1, #prof.children do
            local child = prof.children[i]
            getLogTable(child)
        end
    end
    getLogTable(topProf)
    log(resTab)
    serpLog("--------------profiler stop---------------")
    util.profilers = { children = {}, parent = nil, profiler = nil }
    util.curLv = 0
end

function util.guiChild(elem, childName)
    if (not isValid(elem)) then return nil end
    for ind, child in pairs(elem.children) do if (child.name == childName) then return child end end
end

function util.guiParent(elem, parentName)
    if (not isValid(elem)) then return end
    local curParent = elem.parent
    while (isValid(curParent)) do
        if (curParent.name == parentName) then return curParent end
        curParent = curParent.parent
    end
end

function util.distanceSquared(position1, position2)
    local x1 = position1[1] or position1.x
    local y1 = position1[2] or position1.y
    local x2 = position2[1] or position2.x
    local y2 = position2[2] or position2.y
    return ((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

util.distSq = util.distanceSquared

---@return EntityPrototypeFilters
function util.namesFilter(names)
    local filterRes = {}
    local key, val = next(names)
    if (type(key) == "string") then
        for name, obj in pairs(names) do
            local newFilter = { filter = "name", name = name }
            table.insert(filterRes, newFilter)
        end
    elseif (type(val) == "string") then
        for ind, name in pairs(names) do
            local newFilter = { filter = "name", name = name }
            table.insert(filterRes, newFilter)
        end
    end
    return filterRes
end

function util.deGhostEntity(entity)
    local name = entity.name
    if (name == "entity-ghost") then
        return entity.ghost_name, entity.ghost_type
    else
        return name, entity.prototype.type
    end
end

function util.modIsActive(modName)
    if (script.active_mods[modName]) then return true end
    return false
end

return util
