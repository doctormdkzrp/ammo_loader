---@class Network
Network = {}
Net = Network
Net.objMT = {__index = Net}
Net.className = "Network"
Net.dbName = "Network"

Init.registerFunc(
    function()
        storage.Network = {}
        DB.new(Net.dbName)
        -- storage.Network.nextID = 1
        -- storage.Network.networks = {} ---@type table<number, Network>
    end
)

Init.registerOnLoadFunc(
    function()
        for id, net in pairs(storage.DB[Net.dbName].idCache) do
            setmetatable(net, Net.objMT)
            setmetatable(net.chests, idQ.objMT)
            setmetatable(net.slots, idQ.objMT)
            setmetatable(net.extenders, idQ.objMT)
        end
    end
)

function Net:isValid()
    if (self.chests:size() <= 0) and (self.slots:size() <= 0) and (self.extenders:size() <= 0) then
        return false
    end
    return true
end

function Net:destroy()
    DB.deleteID(Net.dbName, self.id)
end

---@return Network
function Net.getObj(id)
    return DB.getObj(Net.dbName, id)
end

function Net.new()
    local obj = {} ---@type Network
    setmetatable(obj, Net.objMT)
    obj.id = storage.Network.nextID
    storage.Network.nextID = storage.Network.nextID + 1
    storage.Network.networks[obj.id] = obj
    obj._chests = idQ.newChestQ(true)
    obj._slots = idQ.newSlotQ(true)
    obj._extenders = idQ.new(RE.dbName, true)
    return obj
end

function Net.merge(...)
    local args = table.pack(...)
    local finalNet = nil
    for i = 1, #args do
        local arg = args[i]
        local net = arg
        if (type(arg) == "number") then
            net = Net.getObj(arg)
        end
        if (net) then
            if (not finalNet) then
                finalNet = net
            else
                for chest in net._chests:chestIter() do
                    finalNet._chests:push(chest)
                    chest._networkID = finalNet.id
                end
                for slot in net._slots:slotIter() do
                    finalNet._slots:push(slot)
                    slot._networkID = finalNet.id
                end
                for ext in net._extenders:extenderIter() do
                    finalNet._extenders:push(ext)
                    ext._networkID = finalNet.id
                end
            end
        end
    end
    return finalNet
end

function Net:addObj(obj)
    if (not obj) or (not obj:isValid()) then
        return
    end
    if (obj._networkID) then
        local curNet = Net.getObj(obj._networkID)
        if (curNet) then
            curNet:removeObj(obj)
        end
    end
    obj._networkID = self.id
    local cName = obj.className
    if (cName == TC.className) then
        self._chests:push(obj)
    elseif (cName == SL.className) then
        self._slots:push(obj)
    elseif (cName == RE.className) then
        self._extenders:push(obj)
    end
end

function Net:removeObj(obj)
    if (not obj) then
        return
    end
    if (obj._networkID == self.id) then
        obj._networkID = nil
    end
    local cName = obj.className
    if (cName == TC.className) then
        self._chests:softRemove(obj)
    elseif (cName == SL.className) then
        self._slots:softRemove(obj)
    elseif (cName == RE.className) then
        self._extenders:softRemove(obj)
    end
end
