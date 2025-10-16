---@module alGui
alGui = {}
alGui.templates = {}
alGui.handlers = {}
alGui.informatron = {}

alGui.relativeGuiTypes = {
    car = defines.relative_gui_type.car_gui,
    character = defines.relative_gui_type.standalone_character_gui,
    container = defines.relative_gui_type.container_gui,
}
alGui.relativeGuiTypes["ammo-turret"] = defines.relative_gui_type.container_gui
alGui.relativeGuiTypes["artillery-wagon"] = defines.relative_gui_type.container_gui
alGui.relativeGuiTypes["artillery-turret"] = defines.relative_gui_type.container_gui
alGui.relativeGuiTypes["spider-vehicle"] = defines.relative_gui_type.spider_vehicle_gui
alGui.relativeGuiTypes["burner"] = defines.relative_gui_type.entity_with_energy_source_gui

function alGui._init()
    storage.alGui = {}
    storage.alGui.infoFrames = {}
    storage.alGui.renderQ = Queue.new()
    storage.alGui.chestsNeedRender = {}
    storage.alGui.rendersNeedDestroy = {}
    storage.alGui.windows = {}
    storage.alGui.selectedEnts = {}
    storage.alGui.chestFilters = {}
    storage.alGui.chestFilters.playersCurOpenChest = {}
    storage.alGui.chestFilterWindows = {}
    storage.alGui.windowObjects = {}
    storage.alGui.eventListeners = {}
    storage.alGui.textToggleButtons = {}
    storage.alGui.elements = {}
    storage.alGui.players = {}
    storage.alGui.openedEnt = {}
    storage.alGui.reopenPlayer = {}
    alGui.destroyAllModWindows()
    util.clearRenders()
end

Init.registerInitFunc(alGui._init)

function alGui._onLoad()
    setmetatable(storage.alGui.renderQ, Queue.objMT)
    -- for rank, q in pairs(obj.provItems) do
    --     setmetatable(q, idQ.objMT)
    -- end
end

Init.registerOnLoadFunc(alGui._onLoad)

function alGui.playerData(playerOrIndex)
    local data
    if (type(playerOrIndex) == "userdata") then
        if (not isValid(playerOrIndex)) then return end
        playerOrIndex = playerOrIndex.index
    end
    data = storage.alGui.players[playerOrIndex]
    if (not data) then
        data = {}
        storage.alGui.players[playerOrIndex] = data
    end
    return data
end

-- function alGui.windowObjects()
--     return storage.alGui.windowObjects
-- end
function alGui.windowObject(name) return storage.alGui.windowObjects[name] end

alGui.names = {}
alGui.names.initDialogue = "amlo_init_dialogue"
alGui.names.initFlow = "amlo_init_flow1"
alGui.names.initBoxArtillery = "amlo_init_artillery"
alGui.names.initBoxBurners = "amlo_init_burners"
alGui.names.initBoxLocomotives = "amlo_init_locos"

alGui.extraOpts = {
    handlers = 1,
    children = 1,
    save_as = 1,
    style_mods = 1,
    template = 1,
    toggle_target = 1,
    post_build_function = 1
}

function alGui.informatronMenu(player_index)
    return {
        ranks = 1,
        entityFilters = 1
    }
end

function alGui.informatronPageContent(page_name, player_index, element)
    cInform("page content called")
    -- local mainPage = element["algui_info_main_page"]
    -- if (isValid(mainPage)) then
    --     cInform("destroy main page")
    --     mainPage.destroy()
    -- end
    -- local page = alGui.templates.getChildWithName(element, "(algui%_info%_ranks%_page)")
    -- if (isValid(page)) then
    --     cInform("destroy ranks page")
    --     page.destroy()
    -- end
    -- main page
    -- local temps = alGui.templates.informatron
    -- local winObjs = alGui.windowObjects()
    if page_name == "ammo-loader" then
        -- local mainPage = element["algui_info_main_page"]
        -- if (isValid(mainPage)) then
        --     cInform("destroy main page")
        --     mainPage.destroy()
        -- end
        local pageMain = alGui.createMainInfoPage({
            element = element,
            player_index = player_index
        })
    end
    if page_name == "ranks" then
        -- serpLog(element.children)
        -- local page = element.alguiItemRankRoot
        -- if (isValid(page)) then
        --     cInform("destroy ranks page")
        --     page.destroy()
        -- end
        -- element.add({type = "label", caption = "hello"})
        local infoRankElem = alGui.createItemRankGui({
            element = element,
            player_index = player_index
        })
        -- alGui.infoRanks.funcs.refreshRanks(infoRankElem)
        -- serpLog(fin)
    end

    if (page_name == "entityFilters") then
        local forceEntFilterPage = alGui.createForceEntFilterPage({
            element = element,
            player_index = player_index
        })
    end

    -- element.add {type = "button", name = "image_1", style = "mymod_penguin_image_1"}
    --[[
      To make an image you need to require the Informatron mod (so it loads first) then have some code like this in data.lua
      informatron_make_image("mymod_penguin_image_1", "__mymod__/graphics/informatron/pengiun.png", 200, 200)
        "mymod_penguin_image_1" must be unique per image.
        "__mymod__/graphics/informatron/page_1_image.png" is the path to your image.
        200, 200 is the width, height of the image
      ]]
    --
    -- end
end

function alGui.build(parent, t)
    local elems = {}
    local extraOpts = alGui.extraOpts
    local templates = alGui.templates
    if (not t) or (not next(t)) or (not isValid(parent)) then return elems end
    if (t.template) then t = alGui.templates.applyTemplate(t) end
    local opts = {}
    local optsOther = {}
    if (not t) then return end
    for key, val in pairs(t) do
        if (not extraOpts[key]) then
            opts[key] = val
        else
            optsOther[key] = val
        end
    end
    for key, val in pairs(optsOther) do
        local valType = type(val)
        if (valType == "function") then optsOther[key] = val() end
        if (valType == "table") and (val.func) then
            if (val.args) then
                -- optsOther[key] = val.func()
                optsOther[key] = val.func(table.unpack(val.args))
            else
                optsOther[key] = val.func()
            end
        end
    end
    -- serpLog("opts: ", opts)
    local elem = parent.add(opts)
    -- serpLog("optsOther: ", optsOther)
    if (optsOther.children) then
        -- local tabList = {}
        -- if (elem.type == "tabbed-pane") then
        --     for i, childTemplate in pairs(optsOther.children) do
        --         if (childTemplate.type == "tab") then
        --             local catName = string.gsub(childTemplate.save_as, "\\_tab", "")
        --             table.insert(
        --                 tabList,
        --                 {tab = childTemplate.save_as, content = optsOther.children[catName .. "_content"]}
        --             )
        --         end
        --     end
        -- end
        for i, child in pairs(optsOther.children) do
            -- serpLog("child: ", child)
            -- if (type(child) ~= "table") then
            -- break
            -- end
            if (child.template) then
                -- serpLog("child before: ", child)
                child = alGui.templates.applyTemplate(child)
                -- serpLog("child after: ", child)
            end
            local childElems = alGui.build(elem, child)
            if (child.type == "tabbed-pane") then
                -- serpLog(childElems)
                for childName, childElem in pairs(childElems) do
                    if (childElem.type == "tab") then
                        local tabs = childElem.parent.tabs
                        local skip = false
                        for tInd, tabInfo in pairs(tabs) do
                            if (tabInfo.tab == childElem) then
                                skip = true
                                break
                            end
                        end
                        if (not skip) then
                            local catName = string.gsub(childName, "%_tab", "")
                            local contentElem = childElems[catName .. "_content"]
                            -- serpLog(catName, ": ", childElems)
                            -- serpLog(childElems)
                            -- if (catName) and (contentElem) then
                            catName = string.capitalize(catName)
                            catName = string.gsub(catName, "%-", " ")
                            childElem.caption = string.capitalize(catName)
                            contentElem.caption = string.capitalize(catName)
                            -- table.insert(tabList, {tab=childTemplate.save_as, content=optsOther.children[catName.."_content"]})
                            childElem.parent.add_tab(childElem, contentElem)
                            -- end
                        end
                    end
                end
            end
            elems = table.join(elems, childElems)
            -- if (childTemplate.type=="tab") then
            --     local catName = string.gsub(childTemplate.save_as, "\\_tab", "")
            --     table.insert(tabList, {tab=childTemplate.save_as, content=optsOther.children[catName.."_content"]})
            -- end
        end
        -- if (elem.type == "tabbed-pane") then
        --     for i, tabInfo in pairs(tabList) do
        --         elem.add_tab(elems[tabInfo.tab], elems[tabInfo.content])
        --     end
        -- end
    end
    if (optsOther.toggle_target) then
        local targetElems = alGui.build(parent, optsOther.toggle_target)
        if (isValid(targetElems.toggleTarget)) then
            -- alGui.toggleButton.register(elem, targetElems.toggleTarget)
            -- if (not optsOther.handlers) then
            --     optsOther.handlers = "toggleButton"
            -- end
        end
    end
    if (optsOther.save_as) then
        elems[optsOther.save_as] = elem
        -- serpLog(elems)
    end
    if (optsOther.style_mods) and (elem.style) then
        local style = elem.style
        for key, val in pairs(optsOther.style_mods) do style[key] = val end
    end
    -- if (optsOther.handlers) then
    --     serpLog("optsOther.handlers")
    --     serpLog(optsOther.handlers)
    --     local handlers = alGui.handlers.fromString(optsOther.handlers)
    --     for eventName, func in pairs(handlers) do
    --         cInform("adding callback")
    --         alGui.addCallback(elem, eventName, optsOther.handlers)
    --     end
    -- end
    return elems
end

function alGui.callbacks()
    -- if (not info) then
    -- info = {}
    -- storage.alGui.eventListeners[elemID] = info
    -- end
    return storage.alGui.eventListeners
end

-- function alGui.addCallback(elem, event, handlerName)
--     local callbacks = alGui.callbacks()
--     table.insert(callbacks, {
--         element = elem,
--         event = event,
--         handler = handlerName
--     })
-- end

-- function alGui.doCallbacks(e)
--     local callbacks = storage.alGui.eventListeners
--     local elem = e.element
--     local eventName = e.name
--     if (not isValid(elem)) then return end
--     local rmList = {}
--     for i, info in pairs(callbacks) do
--         if (isValid(info.element)) then
--             cInform("callback elem is valid")
--             -- serpLog(info)
--             -- serpLog(e.name)
--             if (info.element == elem) and (e.name == defines.events[info.event]) then
--                 -- serpLog(alGui.handlers[info.handler])
--                 local hand = alGui.handlers.fromString(info.handler)
--                 return hand[info.event](e)
--             else
--                 cInform("not same event or elem")
--             end
--         else
--             table.insert(rmList, i)
--         end
--     end
--     for i, ind in pairs(rmList) do table.remove(callbacks, ind) end
-- end
-- onEvents(
--     alGui.doCallbacks,
--     {
--         -- "on_gui_click",
--         "on_gui_closed",
--         "on_gui_elem_changed",
--         "on_gui_location_changed",
--         "on_gui_opened",
--         "on_gui_switch_state_changed"
--     }
-- )

-- function alGui.playerObjs(player)
--     local objs = storage.alGui.windowObjects[player.index]
--     if (not objs) then
--         objs = {}
--         storage.alGui.windowObjects[player.index] = objs
--     end
--     return objs
-- end

alGui.windows = {}

-- alGui.windows.chestFilter = function(player, chest)
--     if (not isValid(player)) then
--         return
--     end
--     local playerObjs = alGui.playerObjs(player)
--     if (playerObjs["chestFilter"]) then
--         return playerObjs["chestFilter"]
--     elseif (not chest) then
--         return
--     end
--     local obj = {}
--     -- local outer = alGui.build(player.gui.screen, alGui.templates.outerFrame).root
--     -- outer.auto_center = true
--     local win = alGui.chestFilter.templates.create(chest)
--     local elems = alGui.build(player.gui.screen, win)
--     elems.dragBar.drag_target = elems.window
--     elems.titleLabel.drag_target = elems.window
--     elems.window.location = {x = 500, y = 300}
--     -- elems.window.force_auto_center()
--     -- local elem = player.gui.screen.add({type = "frame", caption = "Hello"})
--     -- local elems = {window = elem}
--     obj.chestID = chest.id
--     obj.playerInd = player.index
--     obj.elems = elems
--     obj.name = "chestFilter"
--     playerObjs["chestFilter"] = obj
--     return obj
-- end

-- function alGui.createInitialDialogue(player)
--     local window = player.gui.screen.add {
--         type = "frame",
--         name = alGui.names.initDialogue,
--         direction = "vertical"
--     }
--     window.style.bottom_padding = 4
--     -- local titlebar =
--     --     titlebar.create(
--     --     window,
--     --     "amlo_enable_titlebar",
--     --     {label = {"gui-initial-dialog.titlebar-label-caption"}, draggable = true}
--     -- )
--     local intro = window.add {
--         type = "label",
--         name = "amlo_init_header",
--         caption = {"amlo-gui-captions.initial-dialogue-header"}
--     }
--     local intro = window.add {
--         type = "label",
--         name = "amlo_init_intro",
--         caption = {"amlo-gui-captions.initial-dialogue-intro"}
--     }
--     local flow = window.add {
--         type = "flow",
--         name = alGui.names.initFlow,
--         direction = "horizontal"
--     }
--     flow.add {
--         type = "checkbox",
--         name = alGui.names.initBoxArtillery,
--         -- style = "stretchable_button",
--         caption = {"amlo.artillery"},
--         tooltip = {"gui-initial-dialog.yes-off-button-tooltip"},
--         state = false
--     }
--     flow.add {
--         type = "checkbox",
--         name = alGui.names.initBoxBurners,
--         -- style = "stretchable_button",
--         caption = {"amlo.burner-structs"},
--         tooltip = {"gui-initial-dialog.yes-off-button-tooltip"},
--         state = false
--     }
--     flow.add {
--         type = "checkbox",
--         name = alGui.names.initBoxLocomotives,
--         -- style = "stretchable_button",
--         caption = {"amlo.trains"},
--         tooltip = {"gui-initial-dialog.yes-off-button-tooltip"},
--         state = false
--     }
--     window.force_auto_center()
--     return window
-- end

-- function alGui.toggleWindow(window)
--     if (window.visible) then
--         window.visible = false
--     else
--         window.visible = true
--     end
-- end

-- function alGui.onFilterWindowKey(event)
--     local player = util.eventPlayer(event)
--     if (isValid(player)) then
--         -- local obj = alGui.playerObjs(player).chestFilter
--         -- if (obj) and (obj.elems) and (isValid(obj.elems.window)) then
--         if (player.gui.screen["algui_frame__chest_filters"]) then
--             player.gui.screen["algui_frame__chest_filters"].destroy()
--             return
--         end
--         -- obj.elems.window.destroy()
--         -- alGui.playerObjs(player).chestFilter = nil
--         -- cInform("destroying window and unsetting playerObj[chestFilter]")
--         -- return
--         -- end
--         local chest = TC.getChestFromEnt(player.selected)
--         if (not chest) then
--             cInform("no selected ent")
--             return
--         end
--         storage.alGui.chestFilters.playersCurOpenChest[player.index] = chest.id
--         -- obj = alGui.windows.chestFilter(player, chest)
--         obj = alGui.chestFilter.funcs.create(player, chest)
--         -- alGui.playerObjs(player).chestFilter = {chestID = chest.id, elems = obj}
--         cInform("created window")
--         -- serpLog(obj)
--     end
-- end

--- @return Queue
function alGui.renderQ() return storage.alGui.renderQ end

function alGui.chestsNeedRender() return storage.alGui.chestsNeedRender end

function alGui.rendersNeedDestroy() return storage.alGui.rendersNeedDestroy end

function alGui.renderTick()
    alGui.tickRenderDestroy()
    alGui.tickRenderChests()
end

function alGui.tickRenderChests()
    local chests = storage.alGui.chestsNeedRender
    for chestID, _ in pairs(chests) do
        local chest = TC.getObj(chestID)
        if (not chest) then
            chests[chestID] = nil
        else
            for playerID, info in pairs(chest._renderInfo) do
                chest:highlightConsumers(game.get_player(playerID))
            end
            if (not next(chest._renderInfo)) then chests[chestID] = nil end
        end
    end
end

function alGui.tickRenderDestroy()
    local renders = alGui.rendersNeedDestroy()
    local c = 0
    for id, _ in pairs(renders) do
        if (c >= 500) then break end
        rendering.get_object_by_id(id).destroy()
        renders[id] = nil
        c = c + 1
    end
end

-- function alGui.onPlayerSelectionChangedRender(e)
--     if not Handlers.enabled() then return end
--     local player = game.players[e.player_index]
--     if (not player) or (not gSets.drawRange(player)) or (gSets.drawToggle(player)) then return end
--     util.clearPlayerRenders(player)
--     local selected = player.selected
--     if (not selected) or (not selected.valid) or (selected.force.name ~= player.force.name) then
--         local chestsNeedRender = alGui.chestsNeedRender()
--         for chestID, _ in pairs(chestsNeedRender) do
--             local chest = TC.getObj(chestID)
--             if (not chest) then
--                 chestsNeedRender[chestID] = nil
--             else
--                 chest._renderInfo[player.index] = nil
--             end
--         end
--         return
--     end
--     if (TC.isChestName(selected.name)) then
--         -- elseif (EntDB.contains(selected.name)) then
--         local chest = TC.getChestFromEnt(selected)
--         if (chest) then
--             chest:drawRange(player)
--             chest:highlightConsumers(player)
--         end
--     elseif (SL.entIsTrackable(selected)) then
--         -- local slots = SL.getSlotsFromEntQ(selected)
--         for slot in SL.slotIter() do
--             if (slot.ent == selected) then
--                 local prov = slot:provider()
--                 local slotColor = util.colors.red
--                 if (prov) then
--                     slotColor = util.colors.blue
--                     slot:drawLineToProvider(player)
--                 end
--                 slot:highlight(player, slotColor)
--             end
--         end
--     end
-- end
-- onEvents(alGui.onPlayerSelectionChangedRender, {"on_selected_entity_changed"})

-- function alGui.onPlayerCursorChangedDrawChest(e)
--     local player = util.eventPlayer(e)
--     if (not isValid(player)) then
--         return
--     end
--     local ghost = player.cursor_ghost
--     if (ghost) then

--     end
-- end
-- onEvents(alGui.onPlayerCursorChangedDrawChest, {"on_player_cursor_stack_changed"})

function alGui.destroyAllModWindows()
    local elemList = Queue.new()
    for ind, player in pairs(game.players) do
        for sectionName, section in pairs(player.gui.children) do elemList:push(section) end
    end
    local curElem = elemList:pop()
    while (isValid(curElem)) do
        local mod = curElem.get_mod()
        cInform("mod: ", mod)
        if (mod) and (mod == "ammo-loader") then
            curElem.destroy()
        else
            for ind, child in pairs(curElem.children) do elemList:push(child) end
        end

        curElem = elemList:pop()
    end
end

-- alGui.toggleButton = {
--     register = function(button, element)
--         if (not isValid(button)) or (not isValid(element)) then
--             return
--         end
--         table.insert(storage.alGui.textToggleButtons, {button = button, element = element})
--     end,
--     getElement = function(button)
--         if (not isValid(button)) then
--             return
--         end
--         local toggles = storage.alGui.textToggleButtons
--         local rmList = {}
--         for i, info in pairs(toggles) do
--             local but = info.button
--             local elem = info.element
--             if (not isValid(but)) or (not isValid(elem)) then
--                 table.insert(rmList, i)
--             elseif (but == button) then
--                 return elem
--             end
--         end
--         for i, ind in pairs(rmList) do
--             table.remove(toggles[ind])
--         end
--     end,
--     toggle = function(button)
--         local elem = alGui.toggleButton.getElement(button)
--         if (not elem) then
--             return
--         end
--         cInform("toggleButton toggling...")
--         if (elem.visible) then
--             elem.visible = false
--         else
--             elem.visible = true
--         end
--     end,
--     onClick = function(e)
--         local target = alGui.toggleButton.getElement(e.element)
--         if (not target) then
--             return
--         end
--         alGui.toggleButton.toggle(e.element)
--     end
-- }
-- onEvents(alGui.toggleButton.onClick, {"on_gui_click"})

function alGui.label(text, opts)
    opts = opts or {}
    return table.join({
        type = "label",
        caption = text
    }, opts)
end

-- function alGui.button(text, opts)
--     opts = opts or {}
--     return table.join({
--         type = "label",
--         caption = text
--     }, opts)
-- end

---@param player LuaPlayer
-- function alGui.chestFilterGui2(e)
--     if not isValid(util.eventPlayer(e)) then return end
--     local player = util.eventPlayer(e)
--     local base = e.parent or player.gui.screen
--     if (isValid(base.alguiChestFilterRoot)) then
--         cInform("gui exists")
--         base.alguiChestFilterRoot.destroy()
--     end
--     local selected = player.selected
--     if (not isValid(selected) or not TC.isChestName(selected.name)) then return end
--     local chest = TC.getChestFromEnt(selected)
--     if (not chest) then return end
--     local root = base.add({
--         type = "frame",
--         direction = "vertical",
--         style = "frame",
--         name = "alguiChestFilterRoot",
--         anchor = {
--             gui = defines.relative_gui_type.container_gui,
--             position = defines.relative_gui_position.right,
--             names = {protoNames.chests.loader, protoNames.chests.passiveProvider, protoNames.chests.requester}
--         }
--     })
--     if (not isValid(root)) then return end
--     local titleBar = root.add({
--         type = "flow",
--         direction = "horizontal",
--         children = {
--             {
--                 template = "templates.basic.titleLabel",
--                 args = {title}
--             }, {
--                 template = "templates.basic.dragBar"
--             }, {
--                 template = "templates.basic.closeButtonWhite"
--             }
--         }
--     })
--     local titleLabel = titleBar.add({
--         type = "label",
--         style = "frame_title",
--         tooltip = {"amlo-gui-tooltips.chest-filter-titlebar"},
--         caption = {"amlo-gui-captions.chest-filter-titlebar"}
--     })
--     local titleDragBar = titleBar.add({
--         type = "empty-widget",
--         style = "draggable_space_header"
--     })
--     local dragStyle = titleDragBar.style
--     dragStyle.horizontally_stretchable = true
--     dragStyle.height = 24
--     dragStyle.right_margin = 4
--     dragStyle.minimal_width = 20
--     local closeBut = titleBar.add({
--         type = "sprite-button",
--         style = "frame_action_button",
--         mouse_button_filter = {"left"},
--         name = "alguiChestFilterCloseBut",
--         sprite = "utility/close_white"
--     })
--     if (base == player.gui.screen) then
--         player.opened = root
--         titleDragBar.drag_target = root
--         titleLabel.drag_target = root
--         root.force_auto_center()
--     end
--     local content = root.add({
--         type = "frame",
--         style = "inside_shallow_frame_with_padding",
--         direction = "vertical",
--         name = chest.id
--     })
--     local filterModeContainer = content.add({
--         type = "flow",
--         direction = "horizontal",
--         name = "chestFilterModeContainer"
--     })
--     filterModeContainer.style.bottom_margin = 15
--     filterModeContainer.style.horizontally_stretchable = true
--     filterModeContainer.style.horizontal_align = "center"
--     local filterModeLabel = filterModeContainer.add({
--         type = "label",
--         caption = {"amlo-gui-captions.filter-mode-label"}
--     })
--     local filterModeSwitch = filterModeContainer.add({
--         type = "switch",
--         allow_none_state = false,
--         left_label_caption = {"amlo-gui-captions.filter-mode-left"},
--         right_label_caption = {"amlo-gui-captions.filter-mode-right"},
--         left_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-whitelist"},
--         right_label_tooltip = {"amlo-gui-tooltips.ent-filter-mode-blacklist"},
--         name = "algui_switch__filter_mode__" .. chest.id,
--         switch_state = chest:switchVal()
--     })
--     local filterListContainer = content.add({
--         type = "flow",
--         direction = "horizontal",
--         name = chest.id
--     })
--     if (not chest._entFilter) then
--         filterListContainer.add({
--             type = "choose-elem-button",
--             elem_type = "item"
--         })
--     else
--         for entName, itemName in pairs(chest._entFilter) do
--             local item = filterListContainer.add({
--                 type = "choose-elem-button",
--                 elem_type = "item"
--             })
--             item.elem_value = itemName
--         end
--         filterListContainer.add({
--             type = "choose-elem-button",
--             elem_type = "item"
--         })
--     end
-- end
-- script.on_event(protoNames.keys.filterWindow, alGui.chestFilterGui2)

function alGui.closeButPressed(e)
    local elem = e.element ---@type LuaGuiElement
    local player = util.eventPlayer(e)
    if (not isValid(elem) or not isValid(player)) then return end
    if (elem.name == "alguiChestFilterCloseBut") then
        if (isValid(player.gui.screen.alguiChestFilterRoot)) then
            player.gui.screen.alguiChestFilterRoot.destroy()
        end
    end
end

onEvents(alGui.closeButPressed, { "on_gui_click" })

-- function alGui.getOpenedChestFilterGui(player)
--     if (isValid(player)) and (isValid(player.gui.screen.alguiChestFilterRoot)) then
--         return player.gui.screen.alguiChestFilterRoot
--     end
--     return nil
-- end

-- function alGui.chestFilterPressedE(e)
--     local player = util.eventPlayer(e)
--     if (not player) then return end
--     local gui = alGui.getOpenedChestFilterGui(player)
--     if (not gui) then
--         -- if (player.opened_self) then
--         -- serpLog(player.gui.screen.children_names)
--         -- (isValid(player.opened)) then
--         -- player.opened.alguiItemRankRoot.destroy()
--         -- end
--         return
--     end
--     gui.destroy()
--     -- storage.alGui.closeNextGui = true
-- end
-- onEvents(alGui.chestFilterPressedE,
--          {protoNames.customInputs.e, protoNames.customInputs.escape})

function alGui.guiOpenedSaveEnt(e)
    local player = util.eventPlayer(e)
    local ent = e.entity
    if (not player) or (not isValid(ent)) then return end
    storage.alGui.openedEnt[player.index] = e.entity
end

onEvents(alGui.guiOpenedSaveEnt, { "on_gui_opened" })

function alGui.entityFilterGuiOpened(e)
    local player = util.eventPlayer(e)
    if (not player) or (not isValid(e.entity)) or (not EntDB.isTrackableEnt(e.entity)) then return end
    local guiBase = player.gui.relative
    if (not guiBase) then guiBase = alGui.getPlayerBaseGui(player) end
    local relativeGuiType = EntDB.proto(e.entity.name).relativeGuiType

    -- local openedEnt = player.opened
    -- if (isValid(openedEnt)) then cInform(openedEnt.type) end

    local anchor = {
        gui = relativeGuiType,
        position = alGui.elemOpts.slots.root.anchor.position,
        -- names = EntDB.allNames()
    }
    e.guiAnchor = anchor
    e.parent = guiBase
    if (TC.isChestName(e.entity.name)) then
        alGui.chestFilterGui3(e)
    elseif (SL.entIsTrackable(e.entity)) then
        cInform("alGui ent is trackable")
        alGui.slotFilterGui3(e)
    end
    -- serpLog(e.gui.relative.children[1].)
end

onEvents(alGui.entityFilterGuiOpened, { "on_gui_opened" })

function alGui.getPlayerBaseGui(player)
    if (not isValid(player)) or (not isValid(player.opened)) then return end
    for guiType, baseObj in pairs(player.gui.children) do
        if (isValid(baseObj)) then
            return baseObj
        end
    end
end

-- function alGui.mouseLeftClickPressed(e)
--     local player = util.eventPlayer(e)
--     if (not player) then return end
--     local gui = alGui.getOpenedChestFilterGui(player)
--     if (not gui) then return end
--     local cursorPos = e.cursor_position

-- end

---@param player LuaPlayer
function alGui.chestFilterSave(e)
    local player = util.eventPlayer(e)
    if (not isValid(e.element)) or (not player) then return end
    -- local obj = alGui.playerObjs(player).chestFilter
    local root = player.gui.screen.alguiChestFilterRoot or player.gui.relative.alguiChestFilterRoot
    if (not isValid(root)) or (not isValid(root.children[2])) then return end
    -- cInform(root.children[2].name)
    local content = root.children[2]
    -- local chestID = tonumber(root.children[2].name)
    -- local chest = TC.getObj(chestID)
    local chest = TC.getChestFromEnt(storage.alGui.openedEnt[player.index])
    if (not chest) then return end
    local chestID = chest.id
    local win = root
    local mode = util.FilterModes.whitelist
    local switchState = content.children[1].children[2].switch_state
    if (switchState == "right") then mode = util.FilterModes.blacklist end
    local res = {}
    local emptyCount = 0
    local container = content.children[2]
    -- cInform(container.name)
    for ind, elem in pairs(container.children) do
        if (elem.elem_value) then
            local entProto = prototypes.entity[elem.elem_value]
            -- local itemProto = prototypes.item[elem.elem_value]
            if (entProto) then
                if (SL.entProtoIsTrackable(entProto)) then
                    -- cInform(elem.elem_value)
                    res[entProto.name] = true
                else
                    elem.destroy()
                end
            end
        elseif (emptyCount > 0) then
            elem.destroy()
        else
            emptyCount = emptyCount + 1
        end
    end
    chest:setEntFilter(res, mode)
    if (emptyCount <= 0) then alGui.elemOpts.chests.newFilterListButton(container) end
    -- serpLog("new filter list")
    -- serpLog(chest._entFilter)
    -- serpLog("new filter mode")
    -- serpLog(chest._entFilterMode)
end

onEvents(alGui.chestFilterSave, { "on_gui_elem_changed", "on_gui_switch_state_changed" })

alGui.tabFont = "default-small"
alGui.tabMaxWidth = nil
function alGui.createItemRankGui(e)
    cInform("createItemRankGui")
    local player = util.eventPlayer(e) ---@type LuaPlayer
    local infoWin = e.element ---@type LuaGuiElement
    if (not player) or (not isValid(infoWin)) then return end
    local force = Force.get(player.force.name)
    local root = infoWin.add({
        type = "scroll-pane",
        -- style = "inside_shallow_frame_with_padding",
        -- direction = "vertical",
        -- children = {func = infoTemps.ranks.allCats}
        name = "alguiItemRankRoot"
    })
    -- player.opened = root
    root.style.vertically_squashable = true
    root.style.vertically_stretchable = true
    root.style.natural_height = 500
    local catTypeTabsContainer = root.add({
        type = "tabbed-pane"
    })
    catTypeTabsContainer.style.horizontally_stretchable = true
    local ammoTab = catTypeTabsContainer.add({
        type = "tab",
        caption = "Ammo"
    })
    local fuelTab = catTypeTabsContainer.add({
        type = "tab",
        caption = "Fuel"
    })
    local ammoTabContent = catTypeTabsContainer.add({
        type = "tabbed-pane",
        style = "frame_tabbed_pane"
    })
    ammoTabContent.style.horizontally_stretchable = true
    local fuelTabContent = catTypeTabsContainer.add({
        type = "tabbed-pane",
        style = "frame_tabbed_pane"
    })
    fuelTabContent.style.horizontally_stretchable = true
    catTypeTabsContainer.add_tab(ammoTab, ammoTabContent)
    catTypeTabsContainer.add_tab(fuelTab, fuelTabContent)
    local cats = force:ammoCats()
    local catTabsContainer = ammoTabContent
    local itemProtos = prototypes.item
    for catName, cat in pairs(cats) do
        -- cInform(catName)
        local locName = ItemDB.catLocalName(catName)
        local tab = catTabsContainer.add({
            type = "tab",
            caption = locName
        })
        tab.style.font = alGui.tabFont
        tab.style.maximal_width = alGui.tabMaxWidth
        local tabContent = catTabsContainer.add({
            type = "flow",
            caption = locName,
            direction = "horizontal",
            name = catName
        })
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
            local name = info.name
            local tooltip = alGui.itemRankTooltip(info)
            local sprite = "item/" .. name
            if (not helpers.is_valid_sprite_path(sprite)) then sprite = "utility/questionmark" end
            table.add({
                type = "label",
                caption = tostring(info.rank)
            })
            table.add({
                type = "sprite-button",
                sprite = sprite,
                tooltip = tooltip
            })
            table.add({
                type = "label",
                caption = { "item-name." .. name },
                tooltip = tooltip
            })
            local rankButContainer = table.add({
                type = "flow",
                direction = "vertical",
                name = name
            })
            local rankUpBut = rankButContainer.add({
                type = "button",
                caption = { "amlo-gui-captions.up-arrow" },
                name = "alguiItemRankUp"
            })
            rankUpBut.style.vertically_squashable = true
            rankUpBut.style.height = 18
            local rankDownBut = rankButContainer.add({
                type = "button",
                caption = { "amlo-gui-captions.down-arrow" },
                name = "alguiItemRankDown"
            })
            rankDownBut.style.vertically_squashable = true
            rankDownBut.style.height = 18
        end
        local catResetBut = tabContent.add({
            type = "button",
            caption = { "amlo-gui-captions.item-ranks-cat-reset-button" },
            -- enabled = false,
            name = "alguiItemRankReset"
        })
        catResetBut.style.left_margin = 50
        alGui.refreshItemRanks(table)
    end
    cats = force:fuelCats()
    catTabsContainer = fuelTabContent
    for catName, cat in pairs(cats) do
        -- cInform(catName)
        local locName = ItemDB.catLocalName(catName)
        local tab = catTabsContainer.add({
            type = "tab",
            caption = locName
        })
        tab.style.font = alGui.tabFont
        tab.style.maximal_width = alGui.tabMaxWidth
        local tabContent = catTabsContainer.add({
            type = "flow",
            caption = locName,
            direction = "horizontal",
            name = catName
        })
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
            local name = info.name
            local tooltip = alGui.itemRankTooltip(info)
            local sprite = "item/" .. name
            if (not helpers.is_valid_sprite_path(sprite)) then sprite = "utility/questionmark" end
            table.add({
                type = "label",
                caption = tostring(info.rank)
            })
            table.add({
                type = "sprite-button",
                sprite = sprite,
                tooltip = tooltip
            })
            table.add({
                type = "label",
                caption = { "item-name." .. name },
                tooltip = tooltip
            })
            local rankButContainer = table.add({
                type = "flow",
                direction = "vertical",
                name = name
            })
            local rankUpBut = rankButContainer.add({
                type = "button",
                caption = { "amlo-gui-captions.up-arrow" },
                name = "alguiItemRankUp"
            })
            rankUpBut.style.vertically_squashable = true
            rankUpBut.style.height = 18
            local rankDownBut = rankButContainer.add({
                type = "button",
                caption = { "amlo-gui-captions.down-arrow" },
                name = "alguiItemRankDown"
            })
            rankDownBut.style.vertically_squashable = true
            rankDownBut.style.height = 18
        end
        local catResetBut = tabContent.add({
            type = "button",
            caption = "Reset to Default",
            -- enabled = false,
            name = "alguiItemRankReset"
        })
        catResetBut.style.left_margin = 50
        alGui.refreshItemRanks(table)
    end
end

-- function alGui.getOpenItemRankGui(player)
--     if (not isValid(player)) then return end

-- end

function alGui.itemRankTooltip(itemInf)
    local info = itemInf
    if (not info) then return end
    local tooltip = ""
    if (info.type == "fuel") then
        tooltip = {
            "amlo-gui-tooltips.fuel-item-rank", tostring(info.score), tostring(info.topSpeedMult * 100),
            tostring(info.accelMult * 100)
        }
        return tooltip
    end
    local dmgEffects = ItemDB.getDamageEffects(name)
    if (not dmgEffects) then return end
    local dirDmg = 0
    local dirDmgStr = { "", { "amlo-gui-tooltips.ammo-direct-damage-top" } }
    local aoeDmg = 0
    local aoeDmgStr = { "", { "amlo-gui-tooltips.ammo-aoe-damage-top" } }
    local typeDmg = {}
    for i, effect in pairs(dmgEffects) do
        if (not typeDmg[effect.type]) then typeDmg[effect.type] = 0 end
        typeDmg[effect.type] = typeDmg[effect.type] + effect.amount
        if (not effect.radius) then
            dirDmg = dirDmg + effect.amount
            table.insert(dirDmgStr, { "amlo-gui-tooltips.ammo-direct-damage-line", tostring(effect.amount), effect.type })
            -- dirDmgStr = dirDmgStr .. effect.amount .. " " .. effect.type .. "\n"
        else
            aoeDmg = aoeDmg + effect.amount
            table.insert(aoeDmgStr, {
                "amlo-gui-tooltips.ammo-aoe-damage-line", tostring(effect.amount), effect.type, effect.radius
            })
            -- aoeDmgStr = aoeDmgStr .. effect.amount .. " " .. effect.type ..
            -- " (radius " .. effect.radius .. ")\n"
        end
    end
    local dirDmgTotalStr = { "amlo-gui-tooltips.ammo-direct-damage-total", tostring(dirDmg) }
    local aoeDmgTotalStr = { "amlo-gui-tooltips.ammo-aoe-damage-total", tostring(aoeDmg) }
    local subtotalStr = { "amlo-gui-tooltips.ammo-subtotal", tostring(dirDmg + aoeDmg) }
    local scoreStr = { "amlo-gui-tooltips.ammo-score", tostring(info.score) }
    tooltip = { "", dirDmgStr, "\n", aoeDmgStr, dirDmgTotalStr, aoeDmgTotalStr, subtotalStr, scoreStr, "\n" }
    -- dirDmgStr .. "\n" .. aoeDmgStr .. dirDmgTotalStr .. aoeDmgTotalStr ..
    --     subtotalStr .. scoreStr .. "\n"
    -- local typeDmgStr = "By Type: \n"
    -- for typeName, dmg in pairs(typeDmg) do
    --     typeDmgStr = typeDmgStr .. typeName .. ": " .. dmg .. "\n"
    -- end
    -- tooltip = tooltip .. typeDmgStr
    -- cInform(tooltip)
    return tooltip
end

function alGui.itemRankMove(e)
    if not isValid(e.element) then return end
    local elem = e.element ---@type LuaGuiElement
    local force = Force.get(game.players[elem.player_index].force.name)
    cInform(elem.name)
    if (not elem.name) or ((elem.name ~= "alguiItemRankUp") and (elem.name ~= "alguiItemRankDown")) then return end
    cInform("item rank move")
    local itemObj = force:itemInfo(elem.parent.name)
    if (not itemObj) then
        cInform("itemRankAbort: ", elem.parent.name)
        return
    end
    cInform("itemObjExists")
    local catRanks = force.itemDB.cats[itemObj.category]
    if (elem.name == "alguiItemRankUp" and itemObj.rank > 1) then
        force:setItemRank(itemObj, itemObj.rank - 1)
    elseif (elem.name == "alguiItemRankDown" and itemObj.rank < #catRanks) then
        force:setItemRank(itemObj.name, itemObj.rank + 1)
    end
    alGui.refreshItemRanks(elem.parent.parent)
end

onEvents(alGui.itemRankMove, { "on_gui_click" })

-- function alGui.swapItemRanks(itemName, newRank, force)
--     cInform("swapping item ranks")
--     local itemObj = force:itemInfo(itemName)
--     local oldRank = itemObj.rank
--     local catRanks = ItemDB.category(itemObj.category)
--     local replaceItemObj = force:itemInfo(catRanks[newRank])
--     if (itemObj) and (replaceItemObj) and (newRank ~= oldRank) and
--         (newRank <= #catRanks) and (newRank >= 1) then
--         catRanks[oldRank] = catRanks[newRank]
--         catRanks[newRank] = itemObj.name
--         itemObj.rank = newRank
--         replaceItemObj.rank = oldRank
--         itemObj.rankMod = itemObj.rankMod or 0
--         replaceItemObj.rankMod = replaceItemObj.rankMod or 0
--         local modVal = newRank - oldRank
--         itemObj.rankMod = itemObj.rankMod + modVal
--         replaceItemObj.rankMod = replaceItemObj.rankMod - modVal
--         -- ItemDB.updateRanks(itemObj.category)
--     end
-- end

function alGui.refreshItemRanks(elem)
    if (not isValid(elem)) then return end
    local force = Force.get(game.players[elem.player_index].force.name)
    elem.clear()
    local cat = force.itemDB.cats[elem.name]
    for rank, itemName in pairs(cat) do
        local info = force:itemInfo(itemName)
        local name = info.name
        local tooltip = alGui.itemRankTooltip(info)
        local sprite = "item/" .. name
        if (not helpers.is_valid_sprite_path(sprite)) then sprite = "utility/questionmark" end
        elem.add({
            type = "label",
            caption = tostring(info.rank)
        })
        elem.add({
            type = "sprite-button",
            sprite = sprite,
            tooltip = tooltip
        })
        elem.add({
            type = "label",
            caption = { "item-name." .. name },
            tooltip = tooltip
        })
        local rankButContainer = elem.add({
            type = "flow",
            direction = "vertical",
            name = name
        })
        local rankUpBut = rankButContainer.add({
            type = "button",
            caption = { "amlo-gui-captions.up-arrow" },
            name = "alguiItemRankUp"
        })
        rankUpBut.style.vertically_squashable = true
        rankUpBut.style.height = 18
        local rankDownBut = rankButContainer.add({
            type = "button",
            caption = { "amlo-gui-captions.down-arrow" },
            name = "alguiItemRankDown"
        })
        rankDownBut.style.vertically_squashable = true
        rankDownBut.style.height = 18
    end
end

function alGui.itemRankReset(e)
    if (not isValid(e.element)) or (e.element.name ~= "alguiItemRankReset") then return end
    local force = Force.get(game.players[e.element.player_index].force.name)
    cInform("reset item ranks")
    -- local catContent = e.element.parent
    local catName = e.element.parent.name
    force:resetItemCat(catName)
    alGui.refreshItemRanks(e.element.parent.children[1])
end

onEvents(alGui.itemRankReset, { "on_gui_click" })

function alGui.createMainInfoPage(e)
    if (not isValid(e.element)) or (not isValid(util.eventPlayer(e))) then return end
    ---@type LuaGuiElement
    local root = e.element.add({
        type = "frame",
        style = "frame",
        direction = "vertical",
        name = "alguiInfoMainRoot"
    })
    local summaryLab = root.add({
        type = "label",
        caption = { "amlo-gui-captions.info-main-1" },
        style = "label_style"
    })
    summaryLab.style.single_line = false
    local featOverviewLab = root.add({
        type = "label",
        caption = { "amlo-gui-captions.info-main-features-header" },
        style = "heading_1_label"
    })
    featOverviewLab.style.top_margin = 15
    featOverviewLab.style.bottom_margin = 10
    local ammoLoadingFeatBut = root.add({
        type = "button",
        caption = { "amlo-gui-captions.info-buttons-ammo-loading" },
        enabled = true,
        name = "alguiAmmoLoadingFeat"
    })
    ammoLoadingFeatBut.style.font = "heading-2"
    ammoLoadingFeatBut.style.bottom_margin = 3
    ammoLoadingFeatBut.style.width = 300
    local ammoLoadingFeatContent = root.add({
        type = "flow",
        visible = false,
        direction = "vertical",
        name = "alguiAmmoLoadingFeatContent"
    })
    ammoLoadingFeatContent.style.padding = 5
    ammoLoadingFeatContent.style.top_margin = 5
    ammoLoadingFeatContent.style.bottom_margin = 5
    local ammoLoadingFeatContent1 = ammoLoadingFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-ammo-loading" }
    })
    ammoLoadingFeatContent1.style.single_line = false

    local fuelLoadingFeatBut = root.add({
        type = "button",
        caption = { "amlo-gui-captions.info-buttons-fuel-loading" },
        enabled = true,
        name = "alguiFuelLoadingFeat"
    })
    fuelLoadingFeatBut.style.font = "heading-2"
    fuelLoadingFeatBut.style.bottom_margin = 3
    fuelLoadingFeatBut.style.width = 300
    local fuelLoadingFeatContent = root.add({
        type = "flow",
        visible = false,
        direction = "vertical",
        name = "alguiFuelLoadingFeatContent"
    })
    fuelLoadingFeatContent.style.padding = 5
    fuelLoadingFeatContent.style.top_margin = 5
    fuelLoadingFeatContent.style.bottom_margin = 5
    local fuelLoadingFeatContent1 = fuelLoadingFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-fuel-loading-1" }
    })
    fuelLoadingFeatContent1.style.single_line = false
    local fuelLoadingFeatContent2 = fuelLoadingFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-fuel-loading-2" }
    })
    fuelLoadingFeatContent2.style.font = "default-bold"
    fuelLoadingFeatContent2.style.single_line = false
    fuelLoadingFeatContent2.style.top_margin = 3
    fuelLoadingFeatContent2.style.bottom_margin = 3

    local smartSelectionFeatBut = root.add({
        type = "button",
        caption = { "amlo-gui-captions.info-buttons-smart-loading" },
        enabled = true,
        name = "alguiSmartSelectionFeat"
    })
    smartSelectionFeatBut.style.font = "heading-2"
    smartSelectionFeatBut.style.bottom_margin = 3
    smartSelectionFeatBut.style.width = 300
    local smartSelectionFeatContent = root.add({
        type = "flow",
        visible = false,
        direction = "vertical",
        name = "alguiSmartSelectionFeatContent"
    })
    smartSelectionFeatContent.style.padding = 5
    smartSelectionFeatContent.style.top_margin = 5
    smartSelectionFeatContent.style.bottom_margin = 5
    local smartSelectionFeatContent1 = smartSelectionFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-smart-loading" }
    })
    smartSelectionFeatContent1.style.single_line = false

    local upgradeFeatBut = root.add({
        type = "button",
        caption = { "amlo-gui-captions.info-buttons-upgrading" },
        enabled = true,
        name = "alguiUpgradeFeat"
    })
    upgradeFeatBut.style.font = "heading-2"
    upgradeFeatBut.style.bottom_margin = 3
    upgradeFeatBut.style.width = 300
    local upgradeFeatContent = root.add({
        type = "flow",
        visible = false,
        direction = "vertical",
        name = "alguiUpgradeFeatContent"
    })
    upgradeFeatContent.style.padding = 5
    upgradeFeatContent.style.top_margin = 5
    upgradeFeatContent.style.bottom_margin = 5
    local upgradeFeatContent1 = upgradeFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-upgrading-1" }
    })
    upgradeFeatContent1.style.single_line = false

    local upgradeFeatContent2 = upgradeFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-upgrading-2" }
    })
    upgradeFeatContent2.style.single_line = false
    upgradeFeatContent2.style.font = "default-bold"

    local returnFeatBut = root.add({
        type = "button",
        caption = { "amlo-gui-captions.info-buttons-return" },
        enabled = true,
        name = "alguiReturnFeat"
    })
    returnFeatBut.style.font = "heading-2"
    returnFeatBut.style.bottom_margin = 3
    returnFeatBut.style.width = 300
    local returnFeatContent = root.add({
        type = "flow",
        visible = false,
        direction = "vertical",
        name = "alguiReturnFeatContent"
    })
    returnFeatContent.style.padding = 5
    returnFeatContent.style.top_margin = 5
    returnFeatContent.style.bottom_margin = 5
    local returnFeatContent1 = returnFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-returning-1" }
    })
    returnFeatContent1.style.single_line = false

    local returnFeatContent2 = returnFeatContent.add({
        type = "label",
        caption = { "amlo-gui-captions.info-returning-2" }
    })
    returnFeatContent2.style.single_line = false
    returnFeatContent2.style.font = "default-bold"
end

function alGui.infoMainToggleButtonPress(e)
    if (not isValid(e.element)) or (not isValid(util.eventPlayer(e))) or (not isValid(e.element.parent)) or
        (e.element.parent.name ~= "alguiInfoMainRoot") or (e.element.type ~= "button") then
        return
    end
    local contentName = e.element.name .. "Content"
    local content = e.element.parent[contentName]
    if (content.visible) then
        content.visible = false
    else
        content.visible = true
    end
end

onEvents(alGui.infoMainToggleButtonPress, { "on_gui_click" })

-- function alGui.validEvent(e)
--     if (not isValid(e.element)) or (not isValid(util.eventPlayer(e))) then return false end
--     return true
-- end

---@class guiSwitchMode
alGui.switchModes = {}
alGui.switchModes.whitelist = util.FilterModes.whitelist
alGui.switchModes.blacklist = util.FilterModes.blacklist

function alGui.createForceEntFilterPage(e)
    cInform("createForceEntFilterPage")
    if (not isValid(e.element)) or (not isValid(util.eventPlayer(e))) then return end
    local force = Force.get(util.eventPlayer(e).force.name)
    ---@type LuaGuiElement
    local root = e.element.add({
        type = "scroll-pane",
        name = "alguiForceEntFilterRoot",
        direction = "vertical"
    })
    root.style.vertically_squashable = true
    root.style.vertically_stretchable = true
    root.style.horizontally_squashable = true
    root.style.horizontally_stretchable = true
    root.style.natural_height = 500
    root.style.maximal_width = 1000
    root.style.maximal_height = 500
    -- root.auto_center()

    local intro = root.add({
        type = "label",
        style = "subheader_label",
        caption = { "amlo-gui-captions.info-chest-filters" }
    })
    intro.style.single_line = false
    local filterTable = root.add({
        type = "table",
        name = "alguiForceEntFilterTable",
        column_count = 3,
        draw_horizontal_lines = true,
        vertical_centering = true
    })
    filterTable.style.horizontal_spacing = 20
    filterTable.style.vertical_spacing = 20
    filterTable.style.top_margin = 15
    filterTable.draw_horizontal_line_after_headers = true
    filterTable.style.vertically_stretchable = true
    -- filterTable.style.cell_padding = 5

    local heads = {} ---@type LuaGuiElement[]
    table.insert(heads, filterTable.add({
        type = "label",
        caption = { "amlo-gui-captions.force-filters-ent-select-label" }
    }))
    table.insert(heads, filterTable.add({
        type = "label",
        caption = { "amlo-gui-captions.force-filters-filter-mode-label" }
    }))
    table.insert(heads, filterTable.add({
        type = "label",
        caption = { "amlo-gui-captions.force-filters-item-select-label" }
    }))
    -- for i = 1, #heads do
    -- local cur = heads[i]
    -- cur.style.horizontal_align = "center"
    -- cur.style.horizontally_stretchable = true
    -- cur.style.natural_width = 200
    -- cur.style.horizontally_squashable = true
    -- cur.style.horizontal_align = "right"
    -- end

    local validEntFilters = EntDB.EntNamesFilters()
    local validItemFilters = ItemDB.allItemsFilter()
    local entFilters = force.entFilters
    local indToRemove = {}
    local entNames = {}
    for i = 1, #entFilters do
        local emptyEntFilters = 0
        local curFilter = entFilters[i]
        local mode = curFilter.mode
        cInform(mode)
        local filters = curFilter.filters
        local entName = curFilter.ent
        if (entName) and (prototypes.entity[entName]) and (SL.entProtoIsTrackable(prototypes.entity[entName])) and
            (not entNames[entName]) then
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
                left_label_caption = { "amlo-gui-captions.whitelist" },
                left_label_tooltip = { "amlo-gui-captions.item-filter-mode-whitelist" },
                right_label_caption = { "amlo-gui-captions.blacklist" },
                right_label_tooltip = { "amlo-gui-captions.item-filter-mode-blacklist" },
                name = "alguiForceEntFiltersModeSwitch_" .. tostring(i)
            })
            local itemsContainer = filterTable.add({
                type = "flow",
                direction = "horizontal"
            })
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
        left_label_caption = { "amlo-gui-captions.whitelist" },
        left_label_tooltip = { "amlo-gui-captions.item-filter-mode-whitelist" },
        right_label_caption = { "amlo-gui-captions.blacklist" },
        right_label_tooltip = { "amlo-gui-captions.item-filter-mode-blacklist" },
        name = "alguiForceEntFiltersModeSwitch_" .. tostring(nextInd)
    })
    local itemsContainer = filterTable.add({
        type = "flow",
        direction = "horizontal"
    })
    local itemButton = itemsContainer.add({
        type = "choose-elem-button",
        elem_type = "item",
        elem_filters = validItemFilters,
        name = "alguiForceEntFiltersItemButton_" .. tostring(nextInd) .. "_1"
    })
end

---@param switchVal string @Either "left" or "right"
---@return string @Either "whitelist" or "blacklist"
function alGui.toFilterMode(switchVal)
    if (not switchVal) or (switchVal == "left") then return util.FilterModes.whitelist end
    return util.FilterModes.blacklist
end

---@param filterMode string @Either "whitelist" or "blacklist"
---@return string @Either "left" or "right"
function alGui.toSwitchVal(filterMode)
    if (not filterMode) or (filterMode == util.FilterModes.whitelist) then return "left" end
    return "right"
end

---@return EntityPrototypeFilters
function alGui.validElemFilters()
    ---@type EntityPrototypeFilters
    local filters = {}
    for entType, _ in pairs(EntDB.ammoTypes) do
        local filter = {
            filter = "type",
            type = entType,
            mode = "or"
        }
        table.insert(filters, filter)
    end
    local burnerEntNames = {}
    for name, entProto in pairs(prototypes.entity) do
        if (entProto.burner_prototype) then table.insert(burnerEntNames, entProto.name) end
    end
    table.insert(filters, {
        filter = "name",
        name = burnerEntNames,
        mode = "or"
    })
    return filters
end

---@return ItemPrototypeFilters
function alGui.validItemFilters()
    ---@type ItemPrototypeFilters
    local filters = {
        {
            filter = "fuel",
            mode = "or"
        }, {
        filter = "type",
        type = "ammo",
        mode = "or"
    }
    }
    return filters
end

function alGui.forceEntFilterChanged(e)
    if (not isValid(e.element)) or (not isValid(util.eventPlayer(e))) or
        ((not string.match(e.element.name, "alguiForceEntFiltersEntButton")) and
            (not string.match(e.element.name, "alguiForceEntFiltersItemButton")) and
            (not string.match(e.element.name, "alguiForceEntFiltersModeSwitch"))) then
        return
    end
    local player = util.eventPlayer(e)
    local elem = e.element
    local force = Force.get(player.force.name)
    local tableElem = elem.parent
    if (tableElem.type ~= "table") then tableElem = tableElem.parent end
    if (tableElem.type ~= "table") then return end
    local entFilters = {} ---@type forceEntFilter[]
    local curFilter = {}
    local emptyRows = 0
    local entProtoFilters = alGui.validElemFilters()
    local itemProtoFilters = alGui.validItemFilters()
    local tableChildren = tableElem.children
    local numChildren = #tableChildren
    local destroyList = {}
    local rowIsEmpty = true
    local entNames = {}
    if (numChildren > 3) then
        for i = 4, numChildren do
            local elem = tableChildren[i]
            if ((i - 1) % 3 == 0) then
                rowIsEmpty = true
                local elemVal = elem.elem_value
                curFilter = {}
                table.insert(entFilters, curFilter)
                if (elemVal) and (prototypes.entity[elemVal]) and
                    (SL.entProtoIsTrackable(prototypes.entity[elemVal])) and (not entNames[elemVal]) then
                    entNames[elemVal] = 1
                    curFilter.ent = elemVal
                    rowIsEmpty = false
                else
                    elem.elem_value = nil
                end
            end
            if ((i - 1) % 3 == 1) and (curFilter) then curFilter.mode = alGui.toFilterMode(elem.switch_state) end
            if ((i - 1) % 3 == 2) and (curFilter) then
                curFilter.filters = {}
                local emptyItemButs = 0
                local children = elem.children
                for j = 1, #children do
                    local elem2 = children[j]
                    local val = elem2.elem_value
                    local itemObj = force:itemInfo(val)
                    if (not itemObj) or (table.containsValue(curFilter.filters, val)) then
                        if (emptyItemButs <= 0) then
                            emptyItemButs = emptyItemButs + 1
                            elem2.elem_value = nil
                        else
                            elem2.destroy()
                        end
                    else
                        rowIsEmpty = false
                        table.insert(curFilter.filters, val)
                    end
                end
                if (emptyItemButs <= 0) then
                    elem.add({
                        type = "choose-elem-button",
                        name = "alguiForceEntFiltersItemBut_" .. tostring(i) .. "_" .. tostring(#children + 1),
                        elem_type = "item",
                        elem_filters = itemProtoFilters
                    })
                end
                if (rowIsEmpty) then
                    if (emptyRows <= 0) then
                        emptyRows = emptyRows + 1
                    else
                        table.insert(destroyList, tableChildren[i])
                        table.insert(destroyList, tableChildren[i - 1])
                        table.insert(destroyList, tableChildren[i - 2])
                    end
                end
            end
        end
    end
    cInform("set force entFilters")
    force.entFilters = entFilters
    for i = 1, #destroyList do destroyList[i].destroy() end
    if (emptyRows <= 0) then
        local nextInd = #tableChildren + 1
        local chooseEntButton = tableElem.add({
            type = "choose-elem-button",
            elem_type = "entity",
            elem_filters = entProtoFilters,
            name = "alguiForceEntFiltersEntButton_" .. tostring(nextInd)
        })
        local modeSwitch = tableElem.add({
            type = "switch",
            switch_state = "left",
            left_label_caption = { "amlo-gui-captions.whitelist" },
            left_label_tooltip = { "amlo-gui-captions.item-filter-mode-whitelist" },
            right_label_caption = { "amlo-gui-captions.blacklist" },
            right_label_tooltip = { "amlo-gui-captions.item-filter-mode-blacklist" },
            name = "alguiForceEntFiltersModeSwitch_" .. tostring(nextInd)
        })
        local itemsContainer = tableElem.add({
            type = "flow",
            direction = "horizontal"
        })
        local itemButton = itemsContainer.add({
            type = "choose-elem-button",
            elem_type = "item",
            elem_filters = itemProtoFilters,
            name = "alguiForceEntFiltersItemButton_" .. tostring(nextInd) .. "_1"
        })
    end
    ---@type slotIterFilter
    for slot in force:iterSlots(nil, nil, {}) do
        if (entNames[slot:entName()]) then
            if (slot:filterItem()) and (not slot:force():entFiltersAllow(slot, slot:filterItem())) then
                slot:setProv()
            end
            slot:queueUrgentProvCheck()
        end
    end
end

onEvents(alGui.forceEntFilterChanged, { "on_gui_elem_changed", "on_gui_switch_state_changed" })

alGui.names.close_button = "ammo_loader_close_button"

function alGui.addFrameHeader(elem, caption, closeTargetName)
    closeTargetName = closeTargetName or ""
    local headerContainer = elem.add({
        type = "flow",
        name = "header_for__" .. closeTargetName
    }) ---@type LuaGuiElement
    headerContainer.style.vertically_squashable = true
    headerContainer.style.vertically_stretchable = false
    local caption = headerContainer.add({
        type = "label",
        name = "frame_caption",
        style = "frame_title",
        caption = caption
    })
    local filler = headerContainer.add({
        type = "empty-widget",
        name = "filler",
        style = "draggable_space_header"
    })
    filler.style.height = 24
    filler.style.natural_height = 24
    filler.style.right_margin = 8
    filler.style.horizontally_stretchable = true
    filler.style.vertically_stretchable = true
    -- game.players[elem.player_index].opened = elem
    filler.drag_target = elem.parent
    -- root.force_auto_center()
    local closeBut = headerContainer.add({
        type = "sprite-button",
        name = alGui.names.close_button,
        sprite = "utility/close",
        hovered_sprite = "utility/close",
        clicked_sprite = "utility/close",
        style = "frame_action_button"
    })
end

function alGui.closeButHandler(e)
    local player = util.eventPlayer(e)
    if (not isValid(e.element) or e.element.name ~= alGui.names.close_button or not player) then return end
    local targetName = string.gsub(e.element.parent.name, "header_for__", "")
    local target = util.guiParent(e.element, targetName)
    if (not isValid(target)) then return end
    if (target.name == alGui.names.settings_window) then
        util.guiChild(player.gui.relative, alGui.names.settings_button).visible = true
    end
    target.destroy()
end

onEvents(alGui.closeButHandler, { "on_gui_click" })

function alGui.itemRankPressedE(e)
    local player = util.eventPlayer(e)
    if (not player) then return end
    local gui = player.gui.screen.ammo_loader_settings_window
    if (not gui) then return end
    gui.destroy()
    alGui.playerData(player).reopenPlayer = true
    -- player.opened = player
    -- script
end

onEvents(alGui.itemRankPressedE, { protoNames.customInputs.e, protoNames.customInputs.escape })

function alGui.itemRankCloseGuiHandler(e)
    local player = util.eventPlayer(e)
    if (not player) or (not alGui.playerData(player).reopenPlayer) then return end
    player.opened = player
    alGui.playerData(player).reopenPlayer = false
end

onEvents(alGui.itemRankCloseGuiHandler, { "on_gui_closed" })
