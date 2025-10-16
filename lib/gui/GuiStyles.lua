alGui.GuiStyles = {}
local Styles = alGui.GuiStyles

function alGui.getStyle(name)
    local style = alGui.GuiStyles[name] or {}
    return style
end

Styles.colors = {}

Styles.stretch_both = {
    horizontally_stretchable = true,
    vertically_stretchable = true
}
Styles.stretch_horizontal = {
    horizontally_stretchable = true
}
Styles.stretch_vertical = {
    vertically_stretchable = true
}
Styles.setting_page_button = {
    style = "button",
    horizontally_stretchable = true,
    horizontally_squashable = true,
    vertically_squashable = true,
    -- maximal_height = 20,
    height = 35,
    -- maximal_width = 2000,
    minimal_width = 0,
    padding = 0,
    margin = 0,
    font = 'heading-2'
}
Styles.setting_conent_active = {
    visible = true
}
Styles.setting_conent_inactive = {
    visible = false
}
Styles.setting_page_button_active = {
    style = "green_button"
}
Styles.setting_page_button_inactive = {
    style = "button"
}

function Styles.applyStyle(elem, styleData)
    if (not isValid(elem)) then
        return
    end
    if (styleData["style"]) then
        elem.style = styleData["style"]
    end
    for key, val in pairs(styleData) do
        if (key ~= "style") then
            elem.style[key] = val
        end
    end
end
