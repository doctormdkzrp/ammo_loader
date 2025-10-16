local gsettings = require("lib.gSettings")
createdQ = {}
local CQ = createdQ

createdQ.waitQTriggers = {}
createdQ.waitQTriggers["heli-placement-entity-_-"] = "heli-entity-_-"

-- createdQ.heliNames = {}
-- createdQ.heliNames.placer = "heli-placement-entity-_-"
-- createdQ.heliNames.ent = "heli-entity-_-"
function createdQ._init()
    storage["createdQ"] = {}
    storage["createdQ"]["Q"] = Q.new()
    storage["createdQ"]["last_tick"] = 0
    storage["createdQ"]["isResetting"] = false
    storage["createdQ"]["futureQ"] = Q.new()
    storage["createdQ"]["waitQ"] = Q.new()
    storage["createdQ"]["printLastTick"] = 0
    storage.createdQ.taggedQ = Q.new()
end
-- Init.registerFunc(createdQ._init)

createdQ._onLoad = Init.registerOnLoadFunc(function()
    setmetatable(storage["createdQ"]["Q"], Q.objMT)
    setmetatable(storage["createdQ"]["waitQ"], Q.objMT)
    -- setmetatable(storage["createdQ"]["futureQ"], Q.objMT)
end)

function createdQ.master() return storage["createdQ"] end
function createdQ.waitQ() return createdQ.master()["waitQ"] end
function createdQ.get() return createdQ.master()["Q"] end
createdQ.Q = createdQ.get
createdQ.q = createdQ.get
function createdQ.push(obj)
    -- if (isValid(obj)) then
    -- if (obj.surface.name ~= "nauvis") then
    -- createdQ.tick(obj)
    -- else
    return Q.pushleft(createdQ.Q(), obj)
    -- end
    -- end
end
function createdQ.pop() return Q.pop(createdQ.Q()) end
function createdQ.size() return Q.size(createdQ.Q()) end
function createdQ.getLastTick() return createdQ.master()["last_tick"] end
function createdQ.setLastTick() createdQ.master()["last_tick"] = gSets.tick() end
function createdQ.isResetting() return createdQ.master()["isResetting"] end
function createdQ.startReset()
    createdQ.master()["isResetting"] = true
    storage.createdQ.resetStartTick = game.tick
    -- createdQ.checkAllProfiler = game.create_profiler()
end
function createdQ.finishReset()
    createdQ.master()["isResetting"] = false
    -- if (isValid(createdQ.checkAllProfiler)) then
    if (gSets.debugging()) then
        game.print {"amlo.finish-reset-globals", game.tick - storage.createdQ.resetStartTick}
        Rem.funcs.printNumTracked()
    end
    ctInform("Finished building internal tables.")
    storage.createdQ.resetStartTick = nil
    -- createdQ.checkAllProfiler = nil
end

-- function createdQ.getEntNames()
-- 	local res = {}
-- 	local protos = prototypes.entity
-- 	local chestNames = TC.chestNames("hash")
-- 	local count = 0
-- 	for name, proto in pairs(protos) do
-- 		local burnerProto = proto.burner_prototype
-- 		if (burnerProto) and (burnerProto.fuel_inventory_size > 0) then
-- 			count = count + 1
-- 			res[count] = proto.name
-- 		elseif (proto.type == "car") or (proto.automated_ammo_count) or (proto.type == "artillery-wagon") then
-- 			count = count + 1
-- 			res[count] = proto.name
-- 		elseif (chestNames[proto.name]) then
-- 			count = count + 1
-- 			res[count] = proto.name
-- 		end
-- 	end
-- 	return res
-- end

function createdQ.getForceNames()
    local res = {}
    c = 0
    for name, force in pairs(game.forces) do
        if (name ~= "enemy") and (name ~= "neutral") then
            c = c + 1
            res[c] = name
        end
    end
    return res
end

local typeHash = {}
typeHash["container"] = true
typeHash["logistic-container"] = true
typeHash["artillery-turret"] = true
typeHash["locomotive"] = true
typeHash["artillery-wagon"] = true
typeHash["ammo-turret"] = true
typeHash["car"] = true
typeHash["character"] = true

function createdQ.getCheckEntityNames()
    -- local names = table.deepcopy(protoNames.chests)
    local names = {}
    local c = 0
    for key, chestName in pairs(protoNames.chests) do
        c = c + 1
        table.insert(names, chestName)
    end
    local protos = {}
    if (util.modIsActive(protoNames.mods.repairTurret)) then
        table.insert(names, "repair-turret")
    end
    for name, proto in pairs(prototypes.entity) do
        -- if (not proto.type == "boiler") then
        if (proto.burner_prototype) or (proto.automated_ammo_count) or (proto.type == "character") or (proto.guns) then
            table.insert(protos, proto)
            table.insert(names, proto.name)
        end
        -- end
    end
    return names, protos
end

function createdQ.checkAllEntities(opts)
    opts = opts or {}
    -- local namesHash = EntDB.findEntNames()
    -- local names = {}
    -- local c = 0
    -- for name, _ in pairs(namesHash) do
    -- c = c + 1
    -- names[c] = name
    -- end
    -- for key, chestName in pairs(protoNames.chests) do
    -- c = c + 1
    -- names[c] = chestName
    -- end
    -- local forces = createdQ.getForceNames()
    -- opts.name = names
    -- opts.force = forces

    local names, protos = createdQ.getCheckEntityNames()
    -- local chestNames = protoNames.chests
    -- names = table.join(names, chestNames)
    -- local protos = {}
    -- table.insert(names, "repair-turret")
    -- for name, proto in pairs(prototypes.entity) do
    --     -- if (not proto.type == "boiler") then
    --     if (proto.burner_prototype) or (proto.automated_ammo_count) or (proto.type == "character") or (proto.guns) then
    --         table.insert(protos, proto)
    --         table.insert(names, proto.name)
    --     end
    --     -- end
    -- end
    opts.name = names
    local ents = util.allFind(opts)

    cInform("Queueing all entities...")
    for i = 1, #ents do
        local ent = ents[i]
        createdQ.push(ent)
    end
    -- for ind, player in pairs(game.players) do
    --     if (isValid(player)) then
    --         local char = player.character
    --         if (isValid(char)) then createdQ.push(char) end
    --     end
    -- end
    cInform("Queued ", createdQ.size(), " entities for analysis.")
end
function createdQ.waitQAdd(entName) createdQ.waitQ():push({name = entName, tick = gSets.tick() + 10}) end

function createdQ.tickWaitQ()
    local waitQ = createdQ.waitQ()
    local size = waitQ:size()
    if size <= 0 then return end
    for i = 1, size do
        local pop = waitQ:pop()
        if gSets.tick() <= pop.tick then
            local res = util.allFind({name = pop.name})
            for j = 1, #res do
                local ent = res[j]
                SL.trackAllSlots(ent)
            end
        else
            waitQ:push(pop)
        end
    end
end

---Push all entities requiring waitQ to the main createdQ (for a single surface)
---@param surface LuaSurface
function createdQ.findWaitQEnts(surface)
    local entNames = {}
    local count = 1
    for waitName, entName in pairs(createdQ.waitQTriggers) do
        entNames[count] = entName
        count = count + 1
    end
    local ents = surface.find_entities_filtered{name=entNames}
    for ind, ent in pairs(ents) do
        createdQ.push(ent)
    end
end

function createdQ.tick(cEnt, cEntTags)
    -- local prof = game.create_profiler()
    --
    -- createdQ.futureQTick()
    local maxToCheck = gSets.entsCheckedPerCycle
    local q = storage["createdQ"]["Q"]
    local tableSize = table_size

    if (storage.needCheckWaitQ) then
        cInform("needCheckWaitQ exists")
        for surfName, tick in pairs(storage.needCheckWaitQ) do
            if (game.tick >= tick) then
                local surf = game.get_surface(surfName)
                if (isValid(surf)) then
                    cInform("findWaitQEnts")
                    createdQ.findWaitQEnts(surf)
                end
                storage.needCheckWaitQ[surfName] = nil
            end
        end
        if (tableSize(storage.needCheckWaitQ) <= 0) then
            storage.needCheckWaitQ = nil
        end
    end

    if (cEnt) then
        maxToCheck = 1
        Q.pushleft(q, cEnt)
    end
    local createdQueueSize = CQ.size()
    if (createdQueueSize < maxToCheck) then maxToCheck = createdQueueSize end
    -- if (maxToCheck > 0) then
    --     inform("Created Queue: " .. createdQueueSize .. " items remaining.")
    -- end
    if (CQ.waitQ():size() > 0) then
        cInform('ticking wait q instead')
        CQ.tickWaitQ()
        return
    end
    local c = 0
    if (createdQueueSize > 0) then
        -- Profiler.Start()
        for i = 1, maxToCheck do
            -- while c < maxToCheck do
            local popEnt = CQ.pop()
            local chestObj ---@type Chest
            local slots
            if (isValid(popEnt)) then
                cInform('popEnt valid')
                -- if (string.contains(popEnt.name, "factory")) then
                -- ctInform("Reminder that Loader Chests must be inside factories when using Factorissimo.")
                -- end
                local slotFilters = nil
                local slotFilterMode = nil
                local chestFilters = nil
                local chestFilterMode = nil
                if (cEntTags) then
                    slotFilters = cEntTags[SL.tags.itemFilters]
                    slotFilterMode = cEntTags[SL.tags.filterMode]
                    chestFilters = cEntTags[TC.tags.entFilters]
                    chestFilterMode = cEntTags[TC.tags.filterMode]
                end
                if (TC.isTrackable(popEnt)) then
                    cInform('popEnt is trackable chest')
                    chestObj = TC.new(popEnt)
                    c = c + 1
                    if (chestFilters) and (tableSize(chestFilters)>0) then
                        chestObj:setEntFilter(chestFilters, chestFilterMode)
                    end
                elseif (SL.entIsTrackable(popEnt)) then
                    cInform('popEnt is trackable slot')
                    if (not gSets.ignoreLogisticTurrets()) or (not Mods.LogisticTurrets.modActive()) or (not Mods.LogisticTurrets.isLogisticTurret(popEnt)) then
                        slots = SL.trackAllSlots(popEnt)
                        local numSlots = #slots
                        c = c + numSlots
                        cInform('created '..numSlots..' new slots')
                        if (slotFilters) and (tableSize(slotFilters)>0) then
                            for i=1, numSlots do
                                local slot = slots[i]
                                slot:setAmmoFilter(slotFilters, slotFilterMode)
                            end
                        end
                    end
                elseif (gSets.ignoreLogisticTurrets()) and (Mods.LogisticTurrets.modActive()) and (popEnt.name == Mods.LogisticTurrets._interfaceName) then
                    local slotsToDestroy = Mods.LogisticTurrets.findConnectedSlots(popEnt)
                    for ind, slot in pairs(slotsToDestroy) do
                        slot:destroy()
                    end
                end
            end
            ::continue::
        end
        -- Profiler.Stop("createdQ.tick")
    end
    if (gSets.debugging()) and (c > 0) and (not CQ.isResetting()) then
        Rem.funcs.printNumTracked()
        -- cInform("createdQ: ", c, " created")
    end
    if (CQ.isResetting()) and (CQ.size() <= 0) then CQ.finishReset() end
    -- local cqSize = createdQ.size()
    -- if (cqSize > 0) and (storage.createdQ.printLastTick + 60 >= gSets.tick()) then
    -- storage.createdQ.printLastTick = gSets.tick()
    -- if (cqSize > 0) then
    -- cInform("createdQ: ", cqSize, " remaining")
    -- util.printProfiler(prof, "cqTick")
    -- __DebugAdapter.print({game.print()})
    -- storage["Profiler"] = nil
    -- end
    -- end
end

return createdQ
