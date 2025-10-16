alGui.elemOpts = {}
local elemOpts = alGui.elemOpts

elemOpts.chests = {}
local chestOpts = elemOpts.chests

chestOpts.root = {
    type = "frame",
    direction = "vertical",
    style = "frame",
    name = "alguiChestFilterRoot",
    anchor = {
        gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position.right,
        names = {protoNames.chests.loader, protoNames.chests.passiveProvider, protoNames.chests.requester}
    }
}
chestOpts.titleBar = {type = "flow", direction = "horizontal"}
chestOpts.titleLabel = {
    type = "label",
    style = "frame_title",
    tooltip = {"amlo-gui-tooltips.chest-filter-titlebar"},
    caption = {"amlo-gui-captions.chest-filter-titlebar"}
}
chestOpts.titleDragBar = {type = "empty-widget", style = "draggable_space_header"}

---@param elem LuaGuiElement
function chestOpts.titleDragBarStyle(elem)
    if (not isValid(elem)) then return end
    local dragStyle = elem.style
    dragStyle.horizontally_stretchable = true
    dragStyle.height = 24
    dragStyle.right_margin = 4
    dragStyle.minimal_width = 20
end
chestOpts.closeBut = {
    type = "sprite-button",
    style = "frame_action_button",
    mouse_button_filter = {"left"},
    name = "alguiChestFilterCloseBut",
    sprite = "utility/close"
}
chestOpts.content = {type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical"}
---@param chest Chest
function chestOpts.getContentOpts(chest)
    local opts = table.deepcopy(chestOpts.content)
    opts.name = chest.id
    return opts
end
chestOpts.filterModeContainer = {type = "flow", direction = "horizontal", name = "chestFilterModeContainer"}

---@param elem LuaGuiElement
function chestOpts.filterModeContainerStyle(elem)
    if (not isValid(elem)) then return end
    local style = elem.style
    style.bottom_margin = 15
    style.horizontally_stretchable = true
    style.horizontal_align = "center"
end
chestOpts.filterModeLabel = {type = "label", caption = {"amlo-gui-captions.filter-mode-label"}}
chestOpts.filterModeSwitch = {
    type = "switch",
    allow_none_state = false,
    left_label_caption = {"amlo-gui-captions.filter-mode-left"},
    right_label_caption = {"amlo-gui-captions.filter-mode-right"},
    left_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-whitelist"},
    right_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-blacklist"}
}
---@param chest Chest
function chestOpts.getFilterModeSwitchOpts(chest)
    local opts = table.deepcopy(chestOpts.filterModeSwitch)
    opts.name = "algui_switch__filter_mode__" .. chest.id
    opts.switch_state = chest:switchVal()
    return opts
end
chestOpts.filterListContainer = {type = "flow", direction = "horizontal"}
---@param chest Chest
function chestOpts.getFilterListContainerOpts(chest)
    local opts = table.deepcopy(chestOpts.filterListContainer)
    opts.name = chest.id
    return opts
end
chestOpts.filterListButtonBasic = {type = "choose-elem-button", elem_type = "entity"}
function chestOpts.chooseButtonFilters() return EntDB.EntNamesFilters() end
function chestOpts.getFilterListButtonOpts()
    local opts = table.deepcopy(chestOpts.filterListButtonBasic)
    -- local filters = chestOpts.chooseButtonFilters()
    opts.elem_filters = chestOpts.chooseButtonFilters()
    return opts
end

---@param filterListContainer LuaGuiElement
function chestOpts.newFilterListButton(filterListContainer)
    if (not isValid(filterListContainer)) then return end
    return filterListContainer.add(chestOpts.getFilterListButtonOpts())
end

---@param root LuaGuiElement
function chestOpts.doHeader(root)
    if (not isValid(root)) then return end
    local base = root.parent
    local player = game.players[root.player_index]
    local titleBar = root.add(chestOpts.titleBar)
    local titleLabel = titleBar.add(chestOpts.titleLabel)
    local titleDragBar = titleBar.add(chestOpts.titleDragBar)
    chestOpts.titleDragBarStyle(titleDragBar)
    local closeBut = titleBar.add(chestOpts.closeBut)
    if (base == player.gui.screen) then
        player.opened = root
        titleDragBar.drag_target = root
        titleLabel.drag_target = root
        root.force_auto_center()
    end
end
---@param root LuaGuiElement
---@param chest Chest
function chestOpts.doContent(root, chest)
    if (not isValid(root)) or (not chest) then return end
    local base = root.parent
    local player = game.players[root.player_index]
    local content = root.add(chestOpts.getContentOpts(chest))
    local filterModeContainer = content.add(chestOpts.filterModeContainer)
    chestOpts.filterModeContainerStyle(filterModeContainer)
    local filterModeLabel = filterModeContainer.add(chestOpts.filterModeLabel)
    local filterModeSwitch = filterModeContainer.add(chestOpts.getFilterModeSwitchOpts(chest))
    chestOpts.doEntityFilters(content, chest)
end
---@param parent LuaGuiElement
---@param chest Chest
function chestOpts.doEntityFilters(parent, chest)
    local filterListContainer = parent.add(chestOpts.getFilterListContainerOpts(chest))
    if (not chest._entFilter) then
        chestOpts.newFilterListButton(filterListContainer)
    else
        for entName, t in pairs(chest._entFilter) do
            if (prototypes.entity[entName]) then
                local item = chestOpts.newFilterListButton(filterListContainer)
                item.elem_value = entName
            else
                chest._entFilter[entName] = nil
            end
        end
        chestOpts.newFilterListButton(filterListContainer)
    end
end
---@param parent LuaGuiElement
---@param chest Chest
function chestOpts.doItemFilters(parent, chest)
    local filterListContainer = parent.add(chestOpts.getFilterListContainerOpts(chest))
    if (not chest._entFilter) then
        chestOpts.newFilterListButton(filterListContainer)
    else
        for entName, itemName in pairs(chest._entFilter) do
            local item = chestOpts.newFilterListButton(filterListContainer)
            item.elem_value = itemName
        end
        chestOpts.newFilterListButton(filterListContainer)
    end
end

function alGui.chestFilterGui3(e)
    if not isValid(util.eventPlayer(e)) then return end
    local player = util.eventPlayer(e)
    local base = e.parent or player.gui.screen
    if (isValid(base.alguiSlotFilterRoot)) then
        cInform("gui exists")
        base.alguiSlotFilterRoot.destroy()
    end
    if (isValid(base.alguiChestFilterRoot)) then
        cInform("gui exists")
        base.alguiChestFilterRoot.destroy()
    end
    local selected = player.selected
    if (not isValid(selected) or not TC.isChestName(selected.name)) then return end
    local chest = TC.getChestFromEnt(selected)
    if (not chest) then return end
    local root = base.add(chestOpts.root)
    if (not isValid(root)) then return end
    chestOpts.doHeader(root)
    chestOpts.doContent(root, chest)
end
