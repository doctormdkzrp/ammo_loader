---@class EntQ
EntQ = {}
EntQ.objMT = {__index = Q}

--- @return Queue
function EntQ.new(unique)
    if (unique == nil) then unique = true end
    ---@type Queue
    local q = {first = 0, last = -1}
    setmetatable(q, EntQ.objMT)
    if (unique) then
        q.unique = true
    else
        q.unique = false
    end
    q.entries = {} -- setmetatable({}, {__mode = "v"})
    q.idHash = {}
    -- q.list = q.entries
    return q
end
EntQ.list = function(self) return self.entries end

function EntQ:clear()
    self.first = 0
    self.last = -1
    self.entries = {}
    self.idHash = {}
end

---@param value LuaEntity
function EntQ:pushleft(value)
    if (not isValid(value)) or (not value.unit_number) then return false end
    local unitNum = value.unit_number
    if (self.unique) and (self.idHash[unitNum]) then return false end
    local list = self.entries
    self.first = self.first - 1
    list[self.first] = value
    self.idHash[unitNum] = true
end

---@param value LuaEntity
function EntQ:pushright(value)
    if (not isValid(value)) or (not value.unit_number) then return end
    local unitNum = value.unit_number
    if (self.unique) and (self.idHash[unitNum]) then return false end
    local list = self.entries
    self.last = self.last + 1
    list[self.last] = value
    self.idHash[value.unitNum] = true
end
EntQ.push = EntQ.pushright

---@return LuaEntity
function EntQ:popleft()
    local list = self.entries
    if self:size() <= 0 then return nil end
    local value = list[self.first]
    list[self.first] = nil -- to allow garbage collection
    self.first = self.first + 1
    if (not isValid(value)) then return self:popleft() end
    self.idHash[value.unitNum] = nil
    return value
end
EntQ.pop = EntQ.popleft

---@return LuaEntity
function EntQ:popright()
    local list = self.entries
    if self:size() <= 0 then return nil end
    local value = list[self.last]
    list[self.last] = nil -- to allow garbage collection
    self.last = self.last - 1
    if (not isValid(value)) then return self:popright() end
    self.idHash[value.unitNum] = nil
    return value
end

---@return LuaEntity
function EntQ:peekleft()
    local list = self.entries
    if self:size() <= 0 then return nil end
    local value = list[self.first]
    if (not isValid(value)) then
        list[self.first] = nil
        self.first = self.first + 1
        return self:peekleft()
    end
    return value
end

---@return LuaEntity
function EntQ:peekright()
    local list = self.entries
    if self:size() <= 0 then return nil end
    local value = list[self.last]
    if (not isValid(value)) then
        list[self.last] = nil
        self.last = self.last - 1
        return self:peekright()
    end
    return value
end

---@return LuaEntity
function EntQ:cycle()
    if self:size() <= 0 then return nil end
    local nex = self:pop()
    if (not isValid(nex)) then return self:cycle() end
    self:push(nex)
    return nex
end

---@return bool
function EntQ:isEmpty() return (self:size() <= 0) end
EntQ.isempty = EntQ.isEmpty
EntQ.is_empty = EntQ.isEmpty

---@return int
function EntQ:size() return (self.last - self.first) + 1 end
EntQ.getsize = EntQ.size
EntQ.getSize = EntQ.size
EntQ.get_size = EntQ.size

function EntQ:get_entries() return self.entries end

---@param ent LuaEntity
function EntQ:contains(ent)
    if (not isValid(ent)) or (not ent.unit_number) then return false end
    if (self.idHash[ent.unit_number]) then return true end
    return false
end

---@param ent LuaEntity
function EntQ:removeEnt(ent, forcePurge)
    local unitNum = nil
    if (forcePurge == nil) then forcePurge = false end
    if (not forcePurge) then
        if (not isValid(ent)) or (not ent.unit_number) then return false end
        unitNum = ent.unit_number
        if (not self.idHash[unitNum]) then return false end
    end
    for curEnt in self:iter(nil, true) do
        if (ent == curEnt) then
            if (self.unique) then break end
        else
            self:push(curEnt)
        end
    end
    if (unitNum) then self.idHash[unitNum] = nil end
    return true
end

function EntQ:removeUnitNumber(unitNum)
    if (not self.idHash[unitNum]) then return false end
    for curEnt in self:iter(nil, true) do
        if (unitNum == curEnt.unit_number) then
            if (self.unique) then break end
        else
            self:push(curEnt)
        end
    end
    self.idHash[unitNum] = nil
    return true
end

---@return fun():LuaEntity
function EntQ:iter(limit, pop)
    limit = limit or self:size()
    local i = 0
    local function func()
        i = i + 1
        if (self.first > self.last) or (i > limit) then return end
        if (pop) then
            return self:pop()
        else
            return self:cycle()
        end
    end
    return func
end

return EntQ
