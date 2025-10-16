local names = require("prototypes/names")
data:extend {
    {
        type = "bool-setting",
        name = names.settings.enabled,
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-a[enabled]"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_draw_range",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "Ammo[items]-a[bools]-ab"
    },
    {
        type = "bool-setting",
        name = names.settings.highlightSlots,
        setting_type = "runtime-per-user",
        default_value = true,
        order = "Ammo[items]-a[bools]-ab"
    },
    {
        type = "string-setting",
        name = names.settings.debug,
        setting_type = "runtime-global",
        default_value = names.settings.debugValues.off,
        allowed_values = { names.settings.debugValues.off, names.settings.debugValues.important, names.settings.debugValues.all },
        order = "Ammo[items]-z[debugging]-c"
    }, -- {
    --     type = "bool-setting",
    --     name = "ammo_loader_performance_mode",
    --     setting_type = "runtime-global",
    --     default_value = false,
    --     order = "Ammo[items]-z[debugging]-b"
    -- },
    {
        type = "bool-setting",
        name = "ammo_loader_check_after_research",
        setting_type = "runtime-global",
        default_value = false,
        order = "Ammo[items]-y[modCompat]-a[bools]-a"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_upgrade_ammo",
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-ammo-ab"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_return_items",
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-ammo-a"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_fill_artillery",
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-ammo-b"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_fill_burner_structures",
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-fuel"
    },
    {
        type = "bool-setting",
        name = "ammo_loader_fill_locomotives",
        setting_type = "runtime-global",
        default_value = true,
        order = "Ammo[items]-a[bools]-fuel"
    },
    {
        type = "bool-setting",
        name = names.settings.useCartridges,
        setting_type = "startup",
        default_value = false,
        hidden = true,
        order = "Ammo[items]-a[bools]-b[2]"
    },
    {
        type = "bool-setting",
        name = names.settings.bypassResearch,
        setting_type = "startup",
        default_value = false,
        order = "Ammo[items]-a[bools]-a[1]"
    },
    {
        type = "double-setting",
        name = "ammo_loader_chest_radius",
        setting_type = "runtime-global",
        default_value = 0,
        minimum_value = 0,
        maximum_value = 1000,
        order = "Ammo[items]-b[ints]-a[prefs]"
    }, -- {
    --     type = "double-setting",
    --     name = "ammo_loader_chest_radius_startup",
    --     setting_type = "startup",
    --     default_value = 0,
    --     minimum_value = 0,
    --     maximum_value = 1000,
    --     order = "Ammo[items]-b[ints]-a[prefs]"
    -- },
    {
        type = "bool-setting",
        name = names.settings.crossSurfaces,
        setting_type = "runtime-global",
        default_value = false,
        order = "Ammo[items]-a[bools]-z[prefs]"
    },
    {
        type = "int-setting",
        name = names.settings.providedSlotsPerTick,
        setting_type = "runtime-global",
        default_value = 3,
        minimum_value = 1,
        maximum_value = 1000,
        order = "Ammo[items]-b[ints]-c[prefs]"
    },
    {
        type = "int-setting",
        name = names.settings.itemFillSize,
        setting_type = "runtime-global",
        default_value = 10,
        minimum_value = 1,
        maximum_value = 255,
        order = "Ammo[items]-b[ints]-b[prefs]"
    },
    {
        type = "int-setting",
        name = names.settings.repairToolStackSize,
        setting_type = "startup",
        default_value = 0,
        minimum_value = 0,
        maximum_value = 10000,
        order = "Ammo[items]-b[ints]-b[prefs]"
    },
    {
        type = "bool-setting",
        name = names.settings.ignoreLogisticTurrets,
        setting_type = "runtime-global",
        default_value = false,
        order = "Ammo[items]-y[modCompat]-a[bools]-b"
    }
}
