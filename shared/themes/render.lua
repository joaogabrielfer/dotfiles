local M = {}

local function keys(colors)
  local names = {}
  for name in pairs(colors) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

local function raw(hex)
  return hex:sub(2)
end

function M.alacritty(theme)
  local c = theme.colors
  return ([[
[colors.primary]
background = "%s"
foreground = "%s"
dim_foreground = "%s"
bright_foreground = "%s"

[colors.cursor]
text = "%s"
cursor = "%s"

[colors.vi_mode_cursor]
text = "%s"
cursor = "%s"

[colors.selection]
text = "%s"
background = "%s"

[colors.normal]
black = "%s"
red = "%s"
green = "%s"
yellow = "%s"
blue = "%s"
magenta = "%s"
cyan = "%s"
white = "%s"

[colors.bright]
black = "%s"
red = "%s"
green = "%s"
yellow = "%s"
blue = "%s"
magenta = "%s"
cyan = "%s"
white = "%s"
]]):format(
    c.base, c.text, c.overlay1, c.text,
    c.base, c.rosewater,
    c.base, c.lavender,
    c.base, c.rosewater,
    c.crust, c.red, c.green, c.yellow, c.blue, c.pink, c.teal, c.subtext1,
    c.overlay0, c.red, c.green, c.yellow, c.blue, c.pink, c.teal, c.text
  )
end

function M.hyprland_conf(theme)
  local lines = {}
  for _, name in ipairs(keys(theme.colors)) do
    table.insert(lines, ("$%s = rgb(%s)"):format(name, raw(theme.colors[name])))
    table.insert(lines, ("$%sAlpha = %s"):format(name, raw(theme.colors[name])))
  end
  table.insert(lines, ("$accent = rgb(%s)"):format(raw(theme.colors[theme.accent])))
  table.insert(lines, ("$accentAlpha = %s"):format(raw(theme.colors[theme.accent])))
  return table.concat(lines, "\n") .. "\n"
end

function M.hyprland_lua(theme)
  local lines = { "return {" }
  for _, name in ipairs(keys(theme.colors)) do
    table.insert(lines, ('  %s = "rgb(%s)",'):format(name, raw(theme.colors[name])))
    table.insert(lines, ('  %sAlpha = "%s",'):format(name, raw(theme.colors[name])))
  end
  table.insert(lines, ('  accent = "rgb(%s)",'):format(raw(theme.colors[theme.accent])))
  table.insert(lines, ('  accentAlpha = "%s",'):format(raw(theme.colors[theme.accent])))
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

function M.tmux(theme)
  local lines = {}
  for _, name in ipairs(keys(theme.colors)) do
    local tmux_name = name:gsub("(%d)$", "_%1")
    table.insert(lines, ('set -g @thm_%s "%s"'):format(tmux_name, theme.colors[name]))
  end
  table.insert(lines, ('set -g @thm_accent "%s"'):format(theme.colors[theme.accent]))
  table.insert(lines, ('set -g @thm_bg "%s"'):format(theme.colors.base))
  table.insert(lines, ('set -g @thm_fg "%s"'):format(theme.colors.text))
  return table.concat(lines, "\n") .. "\n"
end

function M.waybar(theme)
  local lines = {}
  for _, name in ipairs(keys(theme.colors)) do
    table.insert(lines, ("@define-color %s %s;"):format(name, theme.colors[name]))
  end
  table.insert(lines, ("@define-color accent %s;"):format(theme.colors[theme.accent]))
  return table.concat(lines, "\n") .. "\n"
end

function M.quickshell(theme)
  local lines = {
    "pragma Singleton",
    "import QtQuick",
    "",
    "QtObject {",
    ('  readonly property string name: "%s"'):format(theme.name),
    ('  readonly property string appearance: "%s"'):format(theme.appearance),
  }
  for _, name in ipairs(keys(theme.colors)) do
    table.insert(lines, ('  readonly property color %s: "%s"'):format(name, theme.colors[name]))
  end
  table.insert(lines, ('  readonly property color accent: "%s"'):format(theme.colors[theme.accent]))
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

function M.all(theme)
  return {
    ["Theme.qml"] = M.quickshell(theme),
    ["alacritty.toml"] = M.alacritty(theme),
    ["hyprland.conf"] = M.hyprland_conf(theme),
    ["hyprland.lua"] = M.hyprland_lua(theme),
    ["qmldir"] = "singleton Theme 1.0 Theme.qml\n",
    ["tmux.conf"] = M.tmux(theme),
    ["waybar.css"] = M.waybar(theme),
  }
end

return M
