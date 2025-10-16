---@class HiddenInserter
HI = {}
HI.protoName = protoNames.hiddenInserter

function HI._preInit()
    local list = util.allFind({ name = HI.protoName })
    for i = 1, #list do
        local ent = list[i]
        if (isValid(ent)) and (not util.stackIsEmpty(ent.held_stack)) then
            local held = ent.held_stack
            local heldStack = { name = held.name, count = held.count }
            local pickup = ent.pickup_target
            if (heldStack.count > 0) and (isValid(pickup)) then
                local amtPickup = pickup.insert(heldStack)
                heldStack.count = heldStack.count - amtPickup
            end
            local drop = ent.drop_target
            if (heldStack.count > 0) and (isValid(drop)) then
                local amtDrop = drop.insert(heldStack)
                heldStack.count = heldStack.count - amtDrop
            end
            if (heldStack.count > 0) then
                local force = Force.get(ent.force.name)
                if (force) and (force.className) and
                    (force.className == "Force") then
                    -- if (force:doReturn()) then
                    heldStack = force:sendToStorage(heldStack, nil,
                        ent.position, true)
                    -- end
                end
            end
            if (heldStack.count > 0) then
                local player = ent.last_user
                if (isValid(player)) and (isValid(player.character)) then
                    local char = player.character
                    local inv = char.get_main_inventory()
                    if (isValid(inv)) and (inv.can_insert(heldStack)) then
                        local didInsert = inv.insert(heldStack)
                        heldStack.count = heldStack.count - didInsert
                    end
                end
            end
            if (heldStack.count > 0) then
                cInform("HI._init() || heldstack not empty. Stack must be spilled or lost: ", heldStack)
            end
        end
        ent.destroy()
    end
end

function HI._preInitPCall() return pcall(HI._preInit) end

Init.registerPreInitFunc(HI._preInitPCall)

function HI._onLoad() end

Init.registerOnLoadFunc(HI._onLoad)

function HI.destroyAllEnts()
    local ents = util.allFind({ name = HI.protoName })
    for i = 1, #ents do
        local ent = ents[i]
        if (isValid(ent)) then ent.destroy() end
    end
end

function HI.destroyOrphans2()
    local ents = util.allFind({ name = HI.protoName })
    for i = 1, #ents do
        local ent = ents[i]
        if (isValid(ent)) then
            local doDestroy = true
            local dropTarget = ent.drop_target
            if (isValid(dropTarget)) then
                doDestroy = false
            else
                cInform("HI drop target invalid.")
            end
            if (doDestroy) then
                cInform("HI destroying orphan ")
                ent.destroy()
            end
        end
    end
end

---Create new HiddenInserter.
---@param slotObj Slot|Chest
---@return LuaEntity
function HI.new(slotObj)
    if (not slotObj) then return nil end
    if (not isValid(slotObj.ent)) then return nil end
    local newInserter = slotObj:surface().create_entity({
        name = protoNames.hiddenInserter,
        position = slotObj:position(),
        force = slotObj:forceName(),
        raise_built = false,
        player = slotObj.ent.last_user
    })
    if not isValid(newInserter) then return nil end

    newInserter.drop_position = slotObj:boundingBoxCenter()
    newInserter.use_filters = true
    newInserter.inserter_filter_mode = "whitelist"
    newInserter.drop_target = slotObj.ent
    newInserter.destructible = false
    newInserter.operable = false
    newInserter.rotatable = false
    newInserter.minable = false
    newInserter.inserter_stack_size_override = 1
    return newInserter
end

return HI
