---@class EntObj
EntObj = {}

---@return Position
function EntObj:position()
    if (self._position) then
        return {x = self._position.x, y = self._position.y}
    end
    local pos = self.ent.position
    return {x = pos.x, y = pos.y}
end

---@return boolean
function EntObj:isValid()
    if (not self) then
        return false
    end
    local tick = gSets.tick()
    local lastCheckTick = self._validCheckTick or 0
    if (self._isValid ~= nil) and (lastCheckTick == tick) then
        return self._isValid
    end
    if (not self.ent) or (not self.ent.valid) then
        self._isValid = false
        self._validCheckTick = tick
        return false
    end
    self._isValid = true
    self._validCheckTick = tick
    return true
end

---@return string
function EntObj:entName()
    if (self._entName) then
        return self._entName
    end
    return self.ent.name
end

---@return string
function EntObj:forceName()
    if (self._forceName) then
        return self._forceName
    end
    return self.ent.force.name
end

---@return Force
function EntObj:force()
    return Force.get(self:forceName())
end

---@return string
function EntObj:surfaceName()
    if (self._surfaceName) then
        return self._surfaceName
    end
    return self.ent.surface.name
end

---@return LuaSurface
function EntObj:surface()
    return game.get_surface(self:surfaceName())
end
