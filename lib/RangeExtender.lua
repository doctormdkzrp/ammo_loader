---@class RangeExtender : EntObj
RangeExtender = {}
---@alias RE RangeExtender
RE = RangeExtender
RE.className = "RangeExtender"
RE.dbName = "RangeExtender"
RE.protoName = protoNames.rangeExtender
RE.objMT = {__index = RE}

Init.registerFunc(
    function()
        DB.new(RE.dbName)
        storage.RE = {}
    end
)

Init.registerOnLoadFunc(
    function()
        for id, ext in pairs(storage.DB[RE.dbName].idCache) do
            setmetatable(ext, RE.objMT)
            setmetatable(ext._suppliedChests, idQ.objMT)
        end
    end
)

function RE.getObj(id)
    return DB.getObj(RE.dbName, id)
end

-- function RE:isValid()
--     if (not self) then
--         return false
--     end
--     local tick = gSets.tick()
--     local lastCheckTick = self._validCheckTick or 0
--     if (self._isValid ~= nil) and (lastCheckTick == tick) then
--         return self._isValid
--     end
--     if (not self.ent) or (not self.ent.valid) then
--         self._isValid = false
--         self._validCheckTick = tick
--         return false
--     end
--     self._isValid = true
--     self._validCheckTick = tick
--     return true
-- end

function RE:destroy()
    DB.deleteID(RE.dbName, self.id)
end

function RE.new(ent)
    if (not isValid(ent)) then
        return
    end
    local obj = {} ---@type RE
    setmetatable(obj, RE.objMT)
    obj._ent = ent
    obj.id = DB.insert(RE.dbName, obj)

    obj._supplyArea = Position.expand_to_area(ent.position, gSets.extenderSupplyRadius)
    obj._suppliedChests = obj:chestsInRangeQ()
    obj._networkID = obj:findOrMakeNetwork()
    obj:setSuppliedChestsNetwork(obj:network())

    return obj
end

for funcName, func in pairs(EntObj) do
    RE[funcName] = func
end

function RE:findOrMakeNetwork()
    local neighs = self:extenderNeighbours()
    local netID = nil
    if (neighs:size() <= 0) then
        self._networkID = Network.new().id
        return self._networkID
    end
    local nets = {}
    local finalNetID = self._networkID
    if (finalNetID) then
        nets[finalNetID] = true
    end
    local finalNet = Net.getObj(finalNetID)
    for ext in neighs:extenderIter() do
        if (ext._networkID) then
            if (not finalNet) then
                finalNetID = ext._networkID
                finalNet = Net.getObj(finalNetID)
            end
            nets[ext._networkID] = true
        end
    end
    if (not finalNet) then
        self._networkID = nil
        return
    end
    local netIDArr = Array.fromHash(nets)
    finalNet = Net.merge(table.unpack(netIDArr))
    if (not finalNet) then
        self._networkID = nil
        return
    end
    finalNet:addObj(self)
end

---@param net Network
function RE:setSuppliedChestsNetwork(net)
    if (not net) then
        return
    end
    for chest in self._suppliedChests:chestIter() do
        net:addObj(chest)
        -- for slot in chest._consumerQ:slotIter() do
        --     net:addObj(slot)
        -- end
    end
end

function RE:network()
    return Network.getObj(self._networkID)
end

---@return extenderQ
function RE:extenderNeighbours()
    local q = idQ.newExtenderQ(true)
    local list = self.ent.neighbours.copper
    for i = 1, #list do
        local ent = list[i]
        if (isValid(ent)) and (ent.name == RE.protoName) and (ent.force.name == self:forceName()) then
            local obj = RE.getObjFromEnt(ent)
            if (obj) then
                q:push(obj)
            end
        end
    end
    return q
end

---@return chestQ
function RE:chestsInRangeQ()
    local q = idQ.newChestQ(true)
    local force = self:force()
    for chest in force:iterChests(nil, nil, {insideArea = self._supplyArea}) do
        q:push(chest)
    end
    return q
end

---@return RangeExtender
function RE.getObjFromEnt(ent)
    if (not isValid(ent)) then
        return
    end
    for id, obj in pairs(storage.DB[RE.dbName].idCache) do
        if (isValid(obj.ent)) and (obj.ent == ent) then
            return obj
        end
    end
end
