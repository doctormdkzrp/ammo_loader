local elemOpts = alGui.elemOpts
elemOpts.slots = {}
local slotOpts = elemOpts.slots

slotOpts.names = {
    gui = {
        closeBut = "alguiSlotFilterCloseBut",
        root = "alguiSlotFilterRoot",
        filterModeContainer = "slotFilterModeContainer"
    }
}
slotOpts.root = {
    type = "frame",
    direction = "vertical",
    style = "frame",
    name = slotOpts.names.gui.root,
    anchor = {
        -- gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position.right
        -- names = EntDB.allNames()
    }
}
slotOpts.titleBar = {
    type = "flow",
    direction = "horizontal"
}
slotOpts.titleLabel = {
    type = "label",
    style = "frame_title",
    tooltip = {"amlo-gui-tooltips.slot-filter-titlebar"},
    caption = {"amlo-gui-captions.slot-filter-titlebar"}
}
slotOpts.titleDragBar = {
    type = "empty-widget",
    style = "draggable_space_header"
}

---@param elem LuaGuiElement
function slotOpts.titleDragBarStyle(elem)
    if (not isValid(elem)) then return end
    local dragStyle = elem.style
    dragStyle.horizontally_stretchable = true
    dragStyle.height = 24
    dragStyle.right_margin = 4
    dragStyle.minimal_width = 20
end
slotOpts.closeBut = {
    type = "sprite-button",
    style = "frame_action_button",
    mouse_button_filter = {"left"},
    name = slotOpts.names.gui.closeBut,
    sprite = "utility/close"
}
slotOpts.content = {
    type = "frame",
    style = "inside_shallow_frame_with_padding",
    direction = "vertical"
}
---@param slot Slot
function slotOpts.getContentOpts(slot)
    local opts = table.deepcopy(slotOpts.content)
    opts.name = slot.id
    return opts
end
slotOpts.filterModeContainer = {
    type = "flow",
    direction = "horizontal",
    name = slotOpts.names.gui.filterModeContainer
}

---@param elem LuaGuiElement
function slotOpts.filterModeContainerStyle(elem)
    if (not isValid(elem)) then return end
    local style = elem.style
    style.bottom_margin = 15
    style.horizontally_stretchable = true
    style.horizontal_align = "center"
end
slotOpts.filterModeLabel = {
    type = "label",
    caption = {"amlo-gui-captions.filter-mode-label"}
}
slotOpts.filterModeSwitch = {
    type = "switch",
    allow_none_state = false,
    left_label_caption = {"amlo-gui-captions.filter-mode-left"},
    right_label_caption = {"amlo-gui-captions.filter-mode-right"},
    left_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-whitelist"},
    right_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-blacklist"}
}
---@param slot Slot
function slotOpts.getFilterModeSwitchOpts(slot)
    local opts = table.deepcopy(slotOpts.filterModeSwitch)
    opts.name = "algui_switch__filter_mode__" .. slot.id
    opts.switch_state = slot:ammoFilterSwitchVal()
    return opts
end
slotOpts.filterListContainer = {
    type = "flow",
    direction = "horizontal"
}
---@param slot Slot
function slotOpts.getFilterListContainerOpts(slot)
    local opts = table.deepcopy(slotOpts.filterListContainer)
    opts.name = slot.id
    return opts
end
slotOpts.filterListButtonBasic = {
    type = "choose-elem-button",
    elem_type = "item"
}

---@param slot Slot
function slotOpts.chooseButtonFilters(ent)
    if (not isValid(ent)) or (not SL.entIsTrackable(ent)) then return {} end
    local entProto = EntDB.proto(ent.name)
    if (not entProto) then return {} end
    local allItems = ItemDB.items()
    local entItemNames = {}
    for invInd, invProto in pairs(entProto.invProtos) do
        for slotInd, slotProto in pairs(invProto) do
            for catName, t in pairs(slotProto.categoryHash) do
                for itemName, itemInf in pairs(ItemDB.items()) do
                    if (itemInf.category == catName) then
                        entItemNames[itemInf.name] = itemInf
                    end
                end
            end
        end
    end
    return util.namesFilter(entItemNames)
end

---@param player LuaPlayer
function slotOpts.getFilterListButtonOpts(player)
    local opts = table.deepcopy(slotOpts.filterListButtonBasic)
    if (not isValid(player)) then return opts end
    local selectedEnt = player.opened
    if (not isValid(selectedEnt)) then return opts end
    -- local filters = slotOpts.chooseButtonFilters()
    opts.elem_filters = slotOpts.chooseButtonFilters(selectedEnt)
    return opts
end

---@param filterListContainer LuaGuiElement
function slotOpts.newFilterListButton(filterListContainer)
    if (not isValid(filterListContainer)) then return end
    return filterListContainer.add(slotOpts.getFilterListButtonOpts(game.get_player(filterListContainer.player_index)))
end

---@param root LuaGuiElement
function slotOpts.doHeader(root)
    if (not isValid(root)) then return end
    local base = root.parent
    local player = game.players[root.player_index]
    local titleBar = root.add(slotOpts.titleBar)
    local titleLabel = titleBar.add(slotOpts.titleLabel)
    local titleDragBar = titleBar.add(slotOpts.titleDragBar)
    slotOpts.titleDragBarStyle(titleDragBar)
    local closeBut = titleBar.add(slotOpts.closeBut)
    if (base == player.gui.screen) then
        player.opened = root
        titleDragBar.drag_target = root
        titleLabel.drag_target = root
        root.force_auto_center()
    end
end
---@param root LuaGuiElement
---@param slots Slot[]
function slotOpts.doContent(root, slots)
    if (not isValid(root)) or (table.isEmpty(slots)) then return end
    local base = root.parent
    local player = game.players[root.player_index]
    local content = root.add(slotOpts.getContentOpts(slots[1]))
    local filterModeContainer = content.add(slotOpts.filterModeContainer)
    slotOpts.filterModeContainerStyle(filterModeContainer)
    local filterModeLabel = filterModeContainer.add(slotOpts.filterModeLabel)
    local filterModeSwitch = filterModeContainer.add(slotOpts.getFilterModeSwitchOpts(slots[1]))
    slotOpts.doItemFilters(content, slots[1])
end
-- function slotOpts.doEntityFilters(parent, slots)
--     if (not isValid(parent)) or (table.isEmpty(slots)) then return end
--     local filterListContainer = parent.add(slotOpts.getFilterListContainerOpts(slots[1]))
--     if (not table.isEmpty(slots[1]._ammoFilter)) then
--         for itemName, t in pairs(slot._ammoFilter) do
--             local item = slotOpts.newFilterListButton(filterListContainer)
--             item.elem_value = itemName
--         end
--     end
--     slotOpts.newFilterListButton(filterListContainer)
--     -- local allFilters = {}
--     -- for i, slot in pairs(slots) do
--     --     if (not table.isEmpty(slot._ammoFilter)) then
--     --         -- slotOpts.newFilterListButton(filterListContainer)
--     --         for entName, t in pairs(slot._ammoFilter) do
--     --             local item = slotOpts.newFilterListButton(filterListContainer)
--     --             item.elem_value = entName
--     --         end
--     --         slotOpts.newFilterListButton(filterListContainer)
--     --     end
--     -- end
-- end
---@param parent LuaGuiElement
---@param slot Slot
function slotOpts.doItemFilters(parent, slot)
    if (not isValid(parent)) or (not slot) then return end
    local filterListContainer = parent.add(slotOpts.getFilterListContainerOpts(slot))
    if (not table.isEmpty(slot._ammoFilter)) then
        for itemName, t in pairs(slot._ammoFilter) do
            if (prototypes.item[itemName]) then
                local item = slotOpts.newFilterListButton(filterListContainer)
                item.elem_value = itemName
            else
                slot._ammoFilter[itemName] = nil
            end
        end
    end
    slotOpts.newFilterListButton(filterListContainer)
end

function alGui.slotFilterGui3(e)
    if not isValid(util.eventPlayer(e)) then
        cInform("slotFilterGui3 player invalid")
        return
    end
    local player = util.eventPlayer(e)
    local base = e.parent
    if (isValid(base.alguiSlotFilterRoot)) then
        cInform("gui exists")
        base.alguiSlotFilterRoot.destroy()
    end
    if (isValid(base.alguiChestFilterRoot)) then
        cInform("gui exists")
        base.alguiChestFilterRoot.destroy()
    end
    local selected = player.opened
    if (not isValid(selected) or not SL.entIsTrackable(selected)) then
        cInform("slotFilterGui3 ent not valid or not trackable")
        return
    end
    local slots = SL.getSlotsFromEnt(selected)
    if (not slots) or (table.isEmpty(slots)) then
        cInform("slotFilterGui3 no slotProtos found")
        return
    end
    local optsRoot = table.deepcopy(slotOpts.root)
    -- local optsRoot = slotOpts.root
    optsRoot.anchor = e.guiAnchor
    local root = base.add(optsRoot)
    if (not isValid(root)) then
        cInform("slotFilterGui3 root invalid")
        return
    end
    slotOpts.doHeader(root)
    slotOpts.doContent(root, slots)
end

function alGui.slotFilterSave(e)
    local player = util.eventPlayer(e)
    if (not isValid(e.element)) or (not player) then return end
    -- local obj = alGui.playerObjs(player).chestFilter
    local root = player.gui.screen.alguiSlotFilterRoot or player.gui.relative.alguiSlotFilterRoot
    if (not isValid(root)) or (not isValid(root.children[2])) then return end
    -- cInform(root.children[2].name)
    local content = root.children[2]
    local slotID = tonumber(root.children[2].name)
    local slot = SL.getObj(slotID)
    if (not slot) then return end
    local win = root
    local mode = util.FilterModes.whitelist
    local switchState = content.children[1].children[2].switch_state
    if (switchState == "right") then mode = util.FilterModes.blacklist end
    local res = {}
    local emptyCount = 0
    local container = content.children[2]
    local allItems = ItemDB.items()
    -- cInform(container.name)
    for ind, elem in pairs(container.children) do
        if (elem.elem_value) then
            local itemProto = prototypes.item[elem.elem_value]
            -- local itemProto = prototypes.item[elem.elem_value]
            if (itemProto) then
                if (allItems[itemProto.name]) then
                    -- cInform(elem.elem_value)
                    res[itemProto.name] = true
                else
                    elem.destroy()
                end
            else
                elem.destroy()
            end
        -- elseif (emptyCount > 0) then
        --     elem.destroy()
        else
            elem.destroy()
        --     emptyCount = emptyCount + 1
        end
    end
    
    -- local allSlots = SL.getSlotsFromEnt(slot.ent)
    local allSlots = SL.getSlotsFromEnt(storage.alGui.openedEnt[player.index])
    for i, curSlot in pairs(allSlots) do
        curSlot:setAmmoFilter(res, mode)
    end
    alGui.elemOpts.slots.newFilterListButton(container)
    -- serpLog("new filter list")
    -- serpLog(chest._entFilter)
    -- serpLog("new filter mode")
    -- serpLog(chest._entFilterMode)
end
onEvents(alGui.slotFilterSave, {"on_gui_elem_changed", "on_gui_switch_state_changed"})