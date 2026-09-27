-- Capture/video bindings and standalone clipboard history.
local capture = "$HOME/.config/hypr/scripts/capture-tools "
local clipboard = "$HOME/.config/hypr/scripts/clipboard-history "

hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd(capture .. "record"))
hl.bind("SUPER + CONTROL + C", hl.dsp.exec_cmd(capture .. "menu"))
hl.bind("SUPER + CONTROL + ALT + E", hl.dsp.exec_cmd(capture .. "edit"))
-- SUPER + CONTROL + period is already used for column resizing.
hl.bind("SUPER + CONTROL + SHIFT + period", hl.dsp.exec_cmd(capture .. "transcode"))
-- SUPER + V already toggles floating windows.
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd(clipboard .. "pick"))

hl.on("hyprland.start", function()
    hl.exec_cmd(clipboard .. "start")
end)
