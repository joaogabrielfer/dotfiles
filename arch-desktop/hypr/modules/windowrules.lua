-- Window rules
local function merge(a, b)
    local out = {}
    for k, v in pairs(a) do out[k] = v end
    for k, v in pairs(b or {}) do out[k] = v end
    return out
end

local function float_center_title(pattern, extra)
    hl.window_rule(merge({
        match = { title = pattern },
        float = true,
        center = true,
    }, extra or {}))
end

local function float_center_class(pattern, extra)
    hl.window_rule(merge({
        match = { class = pattern },
        float = true,
        center = true,
    }, extra or {}))
end

local function float_title(pattern, extra)
    hl.window_rule(merge({
        match = { title = pattern },
        float = true,
    }, extra or {}))
end

local function float_class(pattern, extra)
    hl.window_rule(merge({
        match = { class = pattern },
        float = true,
    }, extra or {}))
end

-- File dialogs / portals

float_center_title([[$^(Open File)(.*)$]])
float_center_title([[$^(Select a File)(.*)$]])

float_center_title([[$^(Choose wallpaper)(.*)$]], {
    size = { "monitor_w * 0.60", "monitor_h * 0.65" },
})

float_center_title([[$^(Open Folder)(.*)$]])
float_center_title([[$^(Save As)(.*)$]])
float_center_title([[$^(Library)(.*)$]])
float_center_title([[$^(File Upload)(.*)$]])
float_center_title([[$^(.*)(wants to save)$]])
float_center_title([[$^(.*)(wants to open)$]])

-- Floating apps

float_class([[$^(blueberry\.py)$]])
float_class([[$^(guifetch)$]]) -- FlafyDev/guifetch

float_center_class([[$^(pavucontrol)$]], {
    size = { "monitor_w * 0.45", "monitor_h * 0.45" },
})

float_center_class([[$^(org.pulseaudio.pavucontrol)$]], {
    size = { "monitor_w * 0.45", "monitor_h * 0.45" },
})

float_center_class([[$^(nm-connection-editor)$]], {
    size = { "monitor_w * 0.45", "monitor_h * 0.45" },
})

float_class([[.*plasmawindowed.*]])
float_class([[kcm_.*]])
float_class([[.*bluedevilwizard]])

float_title([[.*Welcome]])
float_title([[$^(illogical-impulse Settings)$]])
float_title([[.*Shell conflicts.*]])

float_class([[org.freedesktop.impl.portal.desktop.kde]], {
    size = { "monitor_w * 0.60", "monitor_h * 0.65" },
})

float_class([[$^(Zotero)$]], {
    size = { "monitor_w * 0.45", "monitor_h * 0.45" },
})

float_title([[powermenu]])

float_title([[$^(raylib .*)]])

float_center_class("yazi-float")
float_center_class("floating-term")

-- --- Tearing ---

hl.window_rule({
    match = { title = [[.*\.exe]] },
    immediate = true,
})

hl.window_rule({
    match = { title = [[.*minecraft.*]] },
    immediate = true,
})

hl.window_rule({
    match = { class = [[$^(steam_app).*]] },
    immediate = true,
})

-- Expose plugin

hl.workspace_rule({
    workspace = "special:exposed",
    gaps_out = 60,
    gaps_in = 30,
    border_size = 5,
    no_border = false,
    no_shadow = true,
})

-- Ignore maximize requests from apps. You'll probably like this.

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = [[.*]] },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        focus = false,
        class = [[$^$]],
        title = [[$^$]],
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
	animation = "slide bottom"
})

-- hl.layer_rule({
--     name = "vicinae-no-animation",
--     match = { namespace = "vicinae" },
--     no_anim = true,
-- })

-- disable animation for wofi

hl.window_rule({
    name = "wofi-no-animation",
    match = { class = "wofi" },
    no_anim = true,
})

-- Workspace rules

-- hl.workspace_rule({
--     workspace = "1",
--     no_rounding = true,
--     decorate = false,
--     gaps_in = 0,
--     gaps_out = 0,
--     no_border = true,
--     monitor = "DP-1",
-- })
--
-- hl.workspace_rule({
--     workspace = "2",
--     no_rounding = true,
--     decorate = false,
--     gaps_in = 0,
--     gaps_out = 0,
--     no_border = true,
--     monitor = "DP-1",
-- })
--

-- No gaps when the current workspace has a maximized tiled window.
-- f[1] = maximized workspace state.
-- s[false] = ignore special workspaces.

hl.workspace_rule({
    workspace = "f[1]s[false]",
    gaps_in = 0,
    gaps_out = 0,
})

-- Optional: also remove border/rounding in this pseudo-fullscreen mode.
hl.window_rule({
    match = {
        float = false,
        workspace = "f[1]s[false]",
    },
    border_size = 0,
})

hl.window_rule({
    match = {
        float = false,
        workspace = "f[1]s[false]",
    },
    rounding = 0,
})

hl.layer_rule({
    name = "dms-no-animation",
    match = { namespace = "^dms:.*" },
    no_anim = true,
})



-- PORTALS

-- File picker / portal dialogs

local file_picker_size = {
    size = { "monitor_w * 0.60", "monitor_h * 0.65" },
}

float_center_title([[^(Open File)(.*)$]], file_picker_size)
float_center_title([[^(Open Files)(.*)$]], file_picker_size)
float_center_title([[^(Select a File)(.*)$]], file_picker_size)
float_center_title([[^(Select Files)(.*)$]], file_picker_size)
float_center_title([[^(Choose File)(.*)$]], file_picker_size)
float_center_title([[^(Choose Files)(.*)$]], file_picker_size)
float_center_title([[^(File Upload)(.*)$]], file_picker_size)
float_center_title([[^(Open Folder)(.*)$]], file_picker_size)
float_center_title([[^(Select Folder)(.*)$]], file_picker_size)
float_center_title([[^(Save File)(.*)$]], file_picker_size)
float_center_title([[^(Save As)(.*)$]], file_picker_size)
float_center_title([[(.*)(wants to open)$]], file_picker_size)
float_center_title([[(.*)(wants to save)$]], file_picker_size)

-- GNOME / GTK portal windows
float_center_class([[^(xdg-desktop-portal-gnome)$]], file_picker_size)
float_center_class([[^(org\.freedesktop\.impl\.portal\.desktop\.gnome)$]], file_picker_size)
float_center_class([[^(org\.freedesktop\.impl\.portal\.desktop\.gtk)$]], file_picker_size)
float_center_class([[^(org\.gnome\.Nautilus)$]], file_picker_size)

local portal_selector_size = {
    size = { "monitor_w * 0.45", "monitor_h * 0.45" },
}

float_center_title([[^(Screen Sharing)(.*)$]], portal_selector_size)
float_center_title([[^(Share Screen)(.*)$]], portal_selector_size)
float_center_title([[^(Share your screen)(.*)$]], portal_selector_size)
float_center_title([[^(Choose what to share)(.*)$]], portal_selector_size)
float_center_title([[^(Select a monitor)(.*)$]], portal_selector_size)
float_center_title([[^(Select a window)(.*)$]], portal_selector_size)
float_center_title([[^(Select source)(.*)$]], portal_selector_size)
float_center_title([[^(Screenshot)(.*)$]], portal_selector_size)
float_center_title([[^(Take Screenshot)(.*)$]], portal_selector_size)

float_center_class([[^(xdg-desktop-portal-hyprland)$]], portal_selector_size)
float_center_class([[^(org\.freedesktop\.impl\.portal\.desktop\.hyprland)$]], portal_selector_size)
float_center_class([[^(hyprland-share-picker)$]], portal_selector_size)
