local names = require("prototypes.names")
controls = {}
controls.resetKey = {
    type = "custom-input",
    name = "ammo-loader-key-reset",
    key_sequence = "CONTROL + SHIFT + ALT + BACKSPACE",
    consuming = "game-only"
}
controls.toggleEnabledKey = {
    type = "custom-input",
    name = "ammo-loader-key-toggle-enabled",
    key_sequence = "CONTROL + SHIFT + ALT + EQUALS",
    consuming = "game-only"
}
-- controls.upgradeKey = {
--     type = "custom-input",
--     name = "ammo-loader-key-upgrade",
--     key_sequence = "CONTROL + SHIFT + Y",
--     consuming = "game-only"
-- }
controls.returnKey = {
    type = "custom-input",
    name = "ammo-loader-key-return",
    key_sequence = "CONTROL + SHIFT + ALT + HOME",
    consuming = "game-only"
}
controls.filterWindowKey = {
    type = "custom-input",
    name = "ammo-loader-key-filter-window",
    key_sequence = "SHIFT + E",
    consuming = "game-only"
}
controls.acceptKey = {
    type = "custom-input",
    name = names.customInputs.e,
    key_sequence = "E",
    consuming = "none"
}
controls.escapeKey = {
    type = "custom-input",
    name = names.customInputs.escape,
    key_sequence = "ESCAPE",
    consuming = "none"
}
-- controls.mouseLeftClick = {
--     type = "custom-input",
--     name = names.customInputs.mouseLeftClick,
--     key_sequence = "mouse-button-1",
--     consuming = "none"
-- }
controls.toggleRangesKey = {
    type = "custom-input",
    name = "ammo-loader-key-toggle-chest-ranges",
    key_sequence = "CONTROL + SHIFT + ALT + SLASH"
}
controls.manualScanKey = {
    type = "custom-input",
    name = "ammo-loader-key-manual-scan",
    key_sequence = "CONTROL + SHIFT + ALT + R",
    consuming = "game-only"
}
-- controls.cursorPos = {
--     type = "custom-input",
--     name = names.customInputs.cursorPos,
--     linked_game_control = "cursor_position",
--     key_sequence = ""
-- }
for key, val in pairs(controls) do data:extend{val} end
