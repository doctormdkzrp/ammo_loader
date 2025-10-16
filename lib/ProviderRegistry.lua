--- a table containing a Force's registered providers and consumers.
--- Has the format: registry[categoryName->category[itemRank->chestHash[chestID->consumerHash[consumerID->true]]]]
---@class ProviderRegistry
---@field force Force
ProvReg = {}
-- ProvReg.functions = {}
-- local funcs = ProvReg.functions

ProvReg.properties = {
    ---@param obj ProviderRegistry
    ---@param newVal Force|string
    force = function(obj, newVal)
        if (newVal == nil) then
            return Force.get(rawget(obj, '_force'))
        else
            local force = Force.get(newVal)
            rawset(obj, '_force', force.name)
        end
    end,
    -- categories = function(obj)
    --     return obj.force.provCats
    -- end
}

ProvReg.objMT = {
    __index = function(obj, index)
        -- local funcs = ProvReg.functions
        local props = ProvReg.properties
        -- if(funcs[index]) then
        -- return funcs[index]
        if (index == 'categories') then return obj.force.provCats end
        if (props[index]) then
            return props[index](obj)
        elseif (ProvReg[index]) then
            return ProvReg[index]
        else
            return obj.categories[index]
        end
    end,
    __newindex = function(obj, index, newVal)
        local props = ProvReg.properties
        if (props[index]) then
            return props[index](obj, newVal)
            -- elseif index=='categories' then
            -- rawset(obj, 'categories', newVal)
        else
            obj.categories[index] = newVal
        end
    end
}

---@param force Force|string
---@param data table|nil
---@return ProviderRegistry
function ProvReg.new(force, data)
    force = Force.get(force)
    -- local startTable = data == nil and (force.provCats) or (data)
    local newReg = setmetatable({}, ProvReg.objMT) ---@type ProviderRegistry
    newReg.force = force.name
    -- rawset(newReg, 'categories', data)
    -- newReg.categories = data
    return newReg
end

---@param prov Chest|int Chest object or ID
---@return Hash<categoryName, true>
function ProvReg:provCategories(prov)
    local chest = TC.getObj(prov)
    if (not chest) then return {} end
    local result = Hash.new() ---@type Hash
    for catName, catObj in pairs(self.force.provCats) do
        for itemRank, itemObj in pairs(catObj) do
            if (itemObj[chest.id]) then
                result[catName] = true
            end
        end
    end
    return result
end

---@param prov Chest|int Chest object or ID
---@param catName string
---@return boolean
function ProvReg:provHasCategory(prov, catName)
    local chest = TC.getObj(prov)
    local chestProvs = self:provCategories(prov)
    if (chestProvs[catName]) then return true end
    return false
end

function ProvReg.test(force)
    force = Force.get(force)
    local cats = force.provCats
    local reg = ProvReg.new(force, cats)
    for catName, catObj in pairs(reg.categories) do
        cInform(catName)
    end
end

return ProvReg
