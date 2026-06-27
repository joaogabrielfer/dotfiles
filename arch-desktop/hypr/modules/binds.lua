local programs = require("modules.programs")

require("modules.utils")

local main_mod = "SUPER"

-- PROGRAMS
hl.bind(main_mod .. " + B        ", hl.dsp.exec_cmd(programs.browser))
hl.bind(main_mod .. " + T        ", hl.dsp.exec_cmd(programs.terminal))
hl.bind(main_mod .. " + SHIFT + T", hl.dsp.exec_cmd("alacritty --class floating-term -o 'window.opacity = 0.7'"))
hl.bind(main_mod .. " + Return   ", hl.dsp.exec_cmd(programs.menu))
hl.bind(main_mod .. " + O        ", hl.dsp.exec_cmd("xdg-open vicinae://launch/@joaogabriel/obsidian-vicinae-menu/index"))

local yazi_closing = false
hl.bind(main_mod .. " + E", function()
  if yazi_closing then return end
  local active = hl.get_active_window()
  if active ~= nil and active.class == "yazi-float" then
    yazi_closing = true
    hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "Q" }))


    hl.timer(function()
      yazi_closing = false
    end, { timeout = 200, type = "oneshot"})
  else
    hl.dispatch(hl.dsp.exec_cmd(programs.file_manager))
  end
end)


-- CONTROL
hl.bind(main_mod .. " + Q     ", hl.dsp.window.close())
hl.bind(main_mod .. " + V     ", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + M     ", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(main_mod .. " + Escape", hl.dsp.exec_cmd("hyprlock"))
hl.bind(main_mod .. " + TAB   ", function() hl.plugin.hyproverview.toggle() end)

-- FULLSCREEN AND MAXIMIZE
-- hl.bind("SUPER + F", function ()
  -- toggle_focus_mode()
-- end)
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({mode = "fullscreen"}))

-- TMUX
hl.bind(main_mod .. " + S        ", hl.dsp.exec_cmd("$HOME/.config/scripts/tmux-sessions.sh"))
hl.bind(main_mod .. " + SHIFT + N", hl.dsp.exec_cmd("$HOME/.config/scripts/tmux-launcher.sh"))

-- MISC
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o $HOME/pictures/screenshots -z"))
hl.bind(main_mod .. " + Print    ", hl.dsp.exec_cmd("hyprshot -m active -m window -o $HOME/pictures/screenshots"))
hl.bind(main_mod .. " + A        ", hl.dsp.exec_cmd("~/.config/niri/scripts/toggle-audio.sh"))
hl.bind(main_mod .. " + N        ", hl.dsp.exec_cmd("dms ipc call notifications toggle"))

-- HJKL MOVEMENT
hl.bind(main_mod .. " + H", hl.dsp.layout("focus l"))
hl.bind(main_mod .. " + L", hl.dsp.layout("focus r"))
hl.bind(main_mod .. " + K", function () focus_workspace_niri_like("-1") end)
hl.bind(main_mod .. " + J", function () focus_workspace_niri_like("+1") end)
hl.bind(main_mod .. " + PERIOD", hl.dsp.layout("move -50px"), {repeating = true})
hl.bind(main_mod .. " + COMMA ", hl.dsp.layout("move +50px"), {repeating = true})

-- MOUSE MOVEMENT
hl.bind(main_mod .. " + mouse_up", function () focus_workspace_niri_like("-1") end)
hl.bind(main_mod .. " + mouse_down", function () focus_workspace_niri_like("+1") end)

-- MOVING WITH HJKL
hl.bind(main_mod .. " + SHIFT + H", hl.dsp.layout("swapcol l"))
hl.bind(main_mod .. " + SHIFT + L", hl.dsp.layout("swapcol r"))
hl.bind(main_mod .. " + SHIFT + K", function() move_window_to_workspace_niri_like(-1) end)
hl.bind(main_mod .. " + SHIFT + J", function() move_window_to_workspace_niri_like(1) end)

-- RESIZING COLUMNS
hl.bind(main_mod .. " + CONTROL + H", hl.dsp.layout("colresize -0.03"), { repeating = true })
hl.bind(main_mod .. " + CONTROL + L", hl.dsp.layout("colresize +0.03"), { repeating = true })

hl.bind(main_mod .. " + CONTROL + comma", hl.dsp.layout("colresize -0.01"))
hl.bind(main_mod .. " + CONTROL + period", hl.dsp.layout("colresize +0.01"))

hl.bind(main_mod .. " + CONTROL + bracketright", hl.dsp.layout("colresize +conf"))
hl.bind(main_mod .. " + CONTROL + bracketleft", hl.dsp.layout("colresize -conf"))

hl.bind(main_mod .. " + CONTROL + T", hl.dsp.layout("colresize 0.25"))
hl.bind(main_mod .. " + CONTROL + Y", hl.dsp.layout("colresize 0.34"))
hl.bind(main_mod .. " + CONTROL + U", hl.dsp.layout("colresize 0.50"))
hl.bind(main_mod .. " + CONTROL + I", hl.dsp.layout("colresize 0.66"))
hl.bind(main_mod .. " + CONTROL + O", hl.dsp.layout("colresize 0.75"))
hl.bind(main_mod .. " + CONTROL + P", hl.dsp.layout("colresize 1.00"))

hl.bind(main_mod .. " + CONTROL + SHIFT + J", function ()
  local workspace = hl.get_active_workspace()
  if workspace ~= nil then
	local windows = hl.get_workspace_windows(workspace)
	local size = 1/#windows
	for i = 1, #windows do
	  hl.dispatch(hl.dsp.window.resize({x = math.floor(size * 1920), y = 1, window = windows[i]}))
	end
  end
end)

hl.bind(main_mod .. " + CONTROL + J", function ()
  local workspace = hl.get_active_workspace()
  if workspace ~= nil then
	local windows = hl.get_workspace_windows(workspace)
	local size = 1/#windows
	for i = 1, #windows do
	  if windows[i] ~= hl.get_active_window() then
		hl.dispatch(hl.dsp.window.resize({x = math.floor(size * 1920), y = 1, window = windows[i]}))
	  end
	end
  end
end)

hl.bind(main_mod .. " + CONTROL + K", function ()
  local workspace = hl.get_active_workspace()
  if workspace ~= nil then
	local windows = hl.get_workspace_windows(workspace)
	local middle_index = -1
	for i = 1, #windows do
	  if windows[i] == hl.get_active_window() then
		hl.dispatch(hl.dsp.window.fullscreen({mode = "maximized"}))
		middle_index = i
	  end
	end
	local swap_amount = math.ceil(#windows/2) - middle_index
	for _ = 1, #windows do
	  hl.dispatch(hl.dsp.layout("swapcol l"))
	end
	for _ = 1, swap_amount do
	  hl.dispatch(hl.dsp.layout("swapcol r"))
	end
  end
end)

-- DEBUGGING
hl.bind("CONTROL + F1", function()
  hl.notification.create({text = "window size = " .. tostring(hl.get_active_window().size.x) .. ", " .. tostring(hl.get_active_window().size.y), timeout = 5000})end
)

-- MOD [N] MOVEMENT AND MOVING
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(main_mod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(main_mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- MOUSE RESIZING
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- MEDIA CONTROLS
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("dms ipc call audio increment 3"), { locked = true, repeating = true, })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { locked = true, repeating = true, })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true, })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("dms ipc call brightness increment 5 ''"), { locked = true, repeating = true, })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5 ''"), { locked = true, repeating = true, })
