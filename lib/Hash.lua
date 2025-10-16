--- A table that has values as the index to make finding specific values an O(1) operation. Has the format [HashObject -> any].
--- Allows use of (table[value]) to check for existence in datasets.
---@alias Hash table<any, boolean>
Hash = {}

Hash.objMT = {
    __index = Hash
}

---@param data table|nil
---@return Hash
function Hash.new(data)
    local startTable = data == nil and ({}) or (data)
    local newHash = startTable ---@type Hash
    setmetatable(newHash, Hash.objMT)
    return newHash
end

---@param data Hash
---@return table<int, Any>
function Hash.toList(data)
    local list = {}
    for value, bool in pairs(data) do
        table.insert(list, value)
    end
    return list
end

-- ---@param data Hash
-- ---@return function any,bool
-- function Hash.iter(data)
--     local pairsFunc = pairs(data)
--     function iterFunc()
--         return pairsFunc()
--     end
--     return iterFunc
-- end

return Hash