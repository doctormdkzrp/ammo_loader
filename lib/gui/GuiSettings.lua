alGui.settings = {}
local guiSets = alGui.settings
local Styles = alGui.GuiStyles

guiSets.player_gui_type = "screen"

guiSets.names = {}
guiSets.names.settings_button = "ammo_loader_settings_but"

function guiSets.createSettingsButton(e)
    local player = util.eventPlayer(e)
    -- if (e.gui_type ~= defines.gui_type.controller) or (not player) or (not isValid(e.entity)) or (e.entity == player.character) then return end
    if (not player) or (not player.opened_self) then return end
    local butRootElem = player.gui.relative
    -- local rootElem = player.gui[guiSets.player_gui_type]
    -- cInform(rootElem.children_names)
    local oldBut = util.guiChild(butRootElem, guiSets.names.settings_button)
    if (isValid(oldBut)) then
        -- oldBut.destroy()
        return
    end
    local anchorInfo = {gui = defines.relative_gui_type.controller_gui, position = defines.relative_gui_position.right}
    local setButInfo = {
        args = {
            type = "sprite-button",
            name = "ammo_loader_settings_but",
            -- tooltip = {"settings-gui.open-settings"},
            sprite = protoNames.sprites.entities.old.basicLoaderChest,
            style = "tool_button_green",
            tooltip = {"amlo-gui-tooltips.settings-button"}
        },
        style = {width = 40, height = 40, padding = 1},
        root = function(player) return player.gui[guiSets.player_gui_type] end
    }
    -- if (guiSets.player_gui_type == "relative") then
    setButInfo.args.anchor = anchorInfo
    -- end
    local setButElem = butRootElem.add(setButInfo.args)
    for key, val in pairs(setButInfo.style) do setButElem.style[key] = val end
end
onEvents(guiSets.createSettingsButton, {"on_gui_opened"})

guiSets.names.settings_window = "ammo_loader_settings_window"
guiSets.names.content_window = "ammo_loader_settings_content_window"

function guiSets.openSettingsWindow(e)
    local player = util.eventPlayer(e)
    if (not isValid(e.element) or e.element.name ~= guiSets.names.settings_button or not player) then return end
    local setBut = e.element ---@type LuaGuiElement
    local root = player.gui[guiSets.player_gui_type] ---@type LuaGuiElement
    if (Map.contains(root.children_names, guiSets.names.settings_window)) then
        util.guiChild(root, guiSets.names.settings_window).destroy()
        return
    end
    -- setBut.visible = false
    local setWindow = root.add({
        type = "frame",
        name = guiSets.names.settings_window,
        direction = "horizontal",
        style = "invisible_frame"
        -- anchor = {
        --     gui = defines.relative_gui_type.controller_gui,
        --     position = defines.relative_gui_position.c
        -- }
    })
    -- player.opened = setWindow
    -- setWindow.force_auto_center()
    setWindow.style.natural_width = 800
    setWindow.style.natural_height = 600
    setWindow.style.horizontally_stretchable = true
    setWindow.style.vertically_stretchable = true
    setWindow.style.maximal_height = 600
    setWindow.style.maximal_width = 1100
    -- setWindow.auto_center = true
    local pagesWindow = setWindow.add({type = "frame", direction = "vertical", name = guiSets.names.page_list})
    pagesWindow.style.vertically_stretchable = true
    pagesWindow.style.horizontally_stretchable = false
    pagesWindow.style.minimal_width = 175
    local contentWindow = setWindow.add({type = "frame", direction = "vertical", name = guiSets.names.content_window})
    contentWindow.style.horizontally_stretchable = true
    contentWindow.style.vertically_stretchable = true
    alGui.addFrameHeader(contentWindow, {"amlo-gui-text.settings-window-title"}, guiSets.names.settings_window)
    guiSets.addPageToList(pagesWindow, guiSets.names.page_but_prefix .. guiSets.names.rank_tab_suffix, {"amlo-gui-text.settings-page-ranks"})
    guiSets.addPageToList(pagesWindow, guiSets.names.page_but_prefix .. guiSets.names.ent_filter_tab_suffix, {"amlo-gui-text.settings-page-entity-filters"})

    local rankContent = guiSets.addItemRankContent(contentWindow, player)
    rankContent.visible = true

    local entFilterContent = guiSets.addEntFilterContent(contentWindow, player)
    entFilterContent.visible = false

    if (guiSets.player_gui_type == "screen") then
        setWindow.force_auto_center()
        setWindow.bring_to_front()
    end
end
onEvents(guiSets.openSettingsWindow, {"on_gui_click"})

guiSets.names.pages_window = "ammo_loader_settings_pages_window"

guiSets.names.rank_tab_suffix = "ranks"
guiSets.names.ent_filter_tab_suffix = "filters"
guiSets.names.page_but_prefix = "al_page_but__"

---@param listElem LuaGuiElement
function guiSets.addPageToList(listElem, name, caption, tooltip)
    tooltip = tooltip or ""
    -- cInform("page but name: " .. name)
    local pageBut = listElem.add({
        type = "button",
        name = name,
        caption = caption,
        tooltip = tooltip
        -- style = "button"
        -- style = "yellow_slot"
    })
    Styles.applyStyle(pageBut, Styles.setting_page_button)

    return pageBut
end

function guiSets.pageButHandler(e)
    local player = util.eventPlayer(e)
    if (not isValid(e.element) or not string.contains(e.element.name, guiSets.names.page_but_prefix) or not player) then
        -- cInform("not page but")
        return
    end
    local pageName = string.gsub(e.element.name, guiSets.names.page_but_prefix, "")
    local root = util.guiParent(e.element, guiSets.names.settings_window)
    local contentWin = util.guiChild(root, guiSets.names.content_window)
    if (not isValid(contentWin)) then
        cInform("could not find settings content window")
        return
    end
    -- cInform("showing page...")
    e.element = contentWin
    guiSets.showPage(e, pageName)
end
onEvents(guiSets.pageButHandler, {"on_gui_click"})

function guiSets.addContentContainer() end

guiSets.names.item_rank_content_root = "alguiItemRankRoot"
guiSets.names.ent_filter_content_root = "alguiForceEntFilterRoot"

function guiSets.addItemRankContent(parent, player)
    -- cInform("createItemRankGui")
    -- if (not isValid(player)) or (not isValid(parent)) then
    -- return
    -- end
    local infoWin = parent ---@type LuaGuiElement
    local force = Force.get(game.players[infoWin.player_index].force.name)
    local root = infoWin.add({
        type = "scroll-pane",
        -- style = "inside_shallow_frame_with_padding",
        -- direction = "vertical",
        -- children = {func = infoTemps.ranks.allCats}
        name = guiSets.names.item_rank_content_root
    })
    root.style.vertically_stretchable = true
    local catTypeTabsContainer = root.add({type = "tabbed-pane"})
    catTypeTabsContainer.style.horizontally_stretchable = true
    local ammoTab = catTypeTabsContainer.add({type = "tab", caption = {"amlo-gui-captions.item-ranks-ammo-tab-label"}})
    local fuelTab = catTypeTabsContainer.add({type = "tab", caption = {"amlo-gui-captions.item-ranks-fuel-tab-label"}})
    local ammoTabContent = catTypeTabsContainer.add({type = "tabbed-pane", style = "frame_tabbed_pane"})
    ammoTabContent.style.horizontally_stretchable = true
    local fuelTabContent = catTypeTabsContainer.add({type = "tabbed-pane", style = "frame_tabbed_pane"})
    fuelTabContent.style.horizontally_stretchable = true
    catTypeTabsContainer.add_tab(ammoTab, ammoTabContent)
    catTypeTabsContainer.add_tab(fuelTab, fuelTabContent)
    local cats = force:ammoCats()
    local catTabsContainer = ammoTabContent
    local itemProtos = prototypes.item
    for catName, cat in pairs(cats) do
        -- cInform(catName)
        local locName = ItemDB.catLocalName(catName)
        local tab = catTabsContainer.add({type = "tab", caption = locName})
        tab.style.font = alGui.tabFont
        tab.style.maximal_width = alGui.tabMaxWidth
        local tabContent = catTabsContainer.add({type = "flow", caption = locName, direction = "horizontal", name = catName})
        tabContent.style.vertically_stretchable = true
        tabContent.style.padding = 10
        catTabsContainer.add_tab(tab, tabContent)
        local table = tabContent.add({
            type = "table",
            column_count = 4,
            name = catName,
            draw_horizontal_lines = true,
            vertical_centering = true,
            direction = "horizontal"
        })
        table.style.horizontal_spacing = 10
        table.style.vertical_spacing = 10
        for rank, itemName in pairs(cat) do
            local info = force:itemInfo(itemName)
            if (info) then
                local name = info.name
                local tooltip = alGui.itemRankTooltip(info)
                local sprite = "item/" .. name
                if (not helpers.is_valid_sprite_path(sprite)) then sprite = "utility/questionmark" end
                table.add({type = "label", caption = tostring(info.rank)})
                table.add({type = "sprite-button", sprite = sprite, tooltip = tooltip})
                table.add({type = "label", caption = {"item-name." .. name}, tooltip = tooltip})
                local rankButContainer = table.add({type = "flow", direction = "vertical", name = name})
                local rankUpBut = rankButContainer.add({type = "button", caption = {"amlo-gui-captions.up-arrow"}, name = "alguiItemRankUp"})
                rankUpBut.style.vertically_squashable = true
                rankUpBut.style.height = 18
                local rankDownBut = rankButContainer.add({type = "button", caption = {"amlo-gui-captions.down-arrow"}, name = "alguiItemRankDown"})
                rankDownBut.style.vertically_squashable = true
                rankDownBut.style.height = 18
            end
        end
        local catResetBut = tabContent.add({
            type = "button",
            caption = {"amlo-gui-captions.item-ranks-cat-reset-button"},
            -- enabled = false,
            name = "alguiItemRankReset"
        })
        catResetBut.style.left_margin = 50
    end
    cats = force:fuelCats()
    catTabsContainer = fuelTabContent
    for catName, cat in pairs(cats) do
        -- cInform(catName)
        local locName = ItemDB.catLocalName(catName)
        local tab = catTabsContainer.add({type = "tab", caption = locName})
        tab.style.font = alGui.tabFont
        tab.style.maximal_width = alGui.tabMaxWidth
        local tabContent = catTabsContainer.add({type = "flow", caption = locName, direction = "horizontal", name = catName})
        tabContent.style.vertically_stretchable = true
        tabContent.style.padding = 10
        catTabsContainer.add_tab(tab, tabContent)
        local table = tabContent.add({
            type = "table",
            column_count = 4,
            name = catName,
            draw_horizontal_lines = true,
            vertical_centering = true,
            direction = "horizontal"
        })
        table.style.horizontal_spacing = 10
        table.style.vertical_spacing = 10
        for rank, itemName in pairs(cat) do
            local info = force:itemInfo(itemName)
            if (info) then
                local name = info.name
                local tooltip = alGui.itemRankTooltip(info)
                local sprite = "item/" .. name
                if (not helpers.is_valid_sprite_path(sprite)) then sprite = "utility/questionmark" end
                table.add({type = "label", caption = tostring(info.rank)})
                table.add({type = "sprite-button", sprite = sprite, tooltip = tooltip})
                table.add({type = "label", caption = {"item-name." .. name}, tooltip = tooltip})
                local rankButContainer = table.add({type = "flow", direction = "vertical", name = name})
                local rankUpBut = rankButContainer.add({type = "button", caption = {"amlo-gui-captions.up-arrow"}, name = "alguiItemRankUp"})
                rankUpBut.style.vertically_squashable = true
                rankUpBut.style.height = 18
                local rankDownBut = rankButContainer.add({type = "button", caption = {"amlo-gui-captions.down-arrow"}, name = "alguiItemRankDown"})
                rankDownBut.style.vertically_squashable = true
                rankDownBut.style.height = 18
            end
        end
        local catResetBut = tabContent.add({
            type = "button",
            caption = {"amlo-gui-captions.item-ranks-cat-reset-button"},
            -- enabled = false,
            name = "alguiItemRankReset"
        })
        catResetBut.style.left_margin = 50
    end
    return root
end

function guiSets.addEntFilterContent(parent, player)
    if (not isValid(parent)) or (not isValid(player)) then return end
    local force = Force.get(player.force.name)
    ---@type LuaGuiElement
    local root = parent.add({type = "scroll-pane", name = guiSets.names.ent_filter_content_root, direction = "vertical"})
    root.style.vertically_squashable = true
    root.style.vertically_stretchable = true
    root.style.horizontally_squashable = true
    root.style.horizontally_stretchable = true
    root.style.natural_height = 500

    local intro = root.add({type = "label", style = "subheader_label", caption = {"amlo-gui-captions.info-chest-filters"}})
    intro.style.single_line = false
    local filterTable = root.add({type = "table", name = "alguiForceEntFilterTable", column_count = 3, draw_horizontal_lines = true, vertical_centering = true})
    filterTable.style.horizontal_spacing = 20
    filterTable.style.vertical_spacing = 20
    filterTable.style.top_margin = 15
    filterTable.draw_horizontal_line_after_headers = true
    filterTable.style.vertically_stretchable = true
    -- filterTable.style.cell_padding = 5

    local heads = {} ---@type LuaGuiElement[]
    table.insert(heads, filterTable.add({type = "label", caption = {"amlo-gui-captions.force-filters-ent-select-label"}}))
    table.insert(heads, filterTable.add({type = "label", caption = {"amlo-gui-captions.force-filters-filter-mode-label"}}))
    table.insert(heads, filterTable.add({type = "label", caption = {"amlo-gui-captions.force-filters-item-select-label"}}))
    -- for i = 1, #heads do
    -- local cur = heads[i]
    -- cur.style.horizontal_align = "center"
    -- cur.style.horizontally_stretchable = true
    -- cur.style.natural_width = 200
    -- cur.style.horizontally_squashable = true
    -- cur.style.horizontal_align = "right"
    -- end

    local validEntFilters = alGui.validElemFilters()
    local validItemFilters = alGui.validItemFilters()
    local entFilters = force.entFilters
    local indToRemove = {}
    local entNames = {}
    for i = 1, #entFilters do
        local emptyEntFilters = 0
        local curFilter = entFilters[i]
        local mode = curFilter.mode
        -- cInform(mode)
        local filters = curFilter.filters
        local entName = curFilter.ent
        if (entName) and (prototypes.entity[entName]) and (SL.entProtoIsTrackable(prototypes.entity[entName])) and (not entNames[entName]) then
            entNames[entName] = 1
            local chooseEntButton = filterTable.add({
                type = "choose-elem-button",
                elem_type = "entity",
                elem_filters = validEntFilters,
                name = "alguiForceEntFiltersEntButton_" .. tostring(i)
            })
            chooseEntButton.elem_value = entName
            local modeSwitch = filterTable.add({
                type = "switch",
                switch_state = alGui.toSwitchVal(mode),
                left_label_caption = {"amlo-gui-captions.whitelist"},
                left_label_tooltip = "Allow only these items",
                right_label_caption = {"amlo-gui-captions.blacklist"},
                right_label_tooltip = "Do not allow these items",
                name = "alguiForceEntFiltersModeSwitch_" .. tostring(i)
            })
            local itemsContainer = filterTable.add({type = "flow", direction = "horizontal"})
            local items = curFilter.filters
            -- local emptyItemButs = 0
            for j = 1, #items do
                local curItem = items[j]
                local itemObj = force:itemInfo(curItem)
                if (itemObj) then
                    local itemButton = itemsContainer.add({
                        type = "choose-elem-button",
                        elem_type = "item",
                        elem_filters = validItemFilters,
                        name = "alguiForceEntFiltersItemButton_" .. tostring(i) .. "_" .. tostring(j)
                    })
                    itemButton.elem_value = curItem
                end
            end
            local itemButton = itemsContainer.add({
                type = "choose-elem-button",
                elem_type = "item",
                elem_filters = validItemFilters,
                name = "alguiForceEntFiltersItemButton_" .. tostring(i) .. "_" .. tostring(#itemsContainer.children + 1)
            })
        else
            table.insert(indToRemove, i)
        end
    end
    for i = 1, #indToRemove do table.remove(entFilters, indToRemove[i]) end
    local nextInd = #filterTable.children + 1
    local chooseEntButton = filterTable.add({
        type = "choose-elem-button",
        elem_type = "entity",
        elem_filters = validEntFilters,
        name = "alguiForceEntFiltersEntButton_" .. tostring(nextInd)
    })
    local modeSwitch = filterTable.add({
        type = "switch",
        switch_state = "left",
        left_label_caption = {"amlo-gui-captions.whitelist"},
        left_label_tooltip = "Allow only these items",
        right_label_caption = {"amlo-gui-captions.blacklist"},
        right_label_tooltip = "Do not allow these items",
        name = "alguiForceEntFiltersModeSwitch_" .. tostring(nextInd)
    })
    local itemsContainer = filterTable.add({type = "flow", direction = "horizontal"})
    local itemButton = itemsContainer.add({
        type = "choose-elem-button",
        elem_type = "item",
        elem_filters = validItemFilters,
        name = "alguiForceEntFiltersItemButton_" .. tostring(nextInd) .. "_1"
    })
    return root
end

guiSets.names.main_window = "ammo_loader_settings_main_window"
guiSets.names.page_list = "ammo_loader_settings_page_list"

--- @param elem LuaGuiElement
--- @param page string
function guiSets.showPage(e, page)
    if (not isValid(e.element) or not util.eventPlayer(e)) then return end
    local elem = e.element
    local ranksElem = util.guiChild(elem, guiSets.names.item_rank_content_root)
    local filtersElem = util.guiChild(elem, guiSets.names.ent_filter_content_root)
    if (not ranksElem or not filtersElem) then return end
    if (page == "ranks") then
        ranksElem.visible = true
        filtersElem.visible = false
    elseif (page == "filters") then
        ranksElem.visible = false
        filtersElem.visible = true
    end
end

--- @param elem LuaGuiElement
function guiSets.setActivePageButton(elem) elem.style.font_color = {r = 1, g = 0.5, b = 0.5, a = 1} end
