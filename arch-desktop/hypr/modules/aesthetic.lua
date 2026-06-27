local colors = require("modules.theme")

hl.config({
  general = {
	gaps_in = 5,
	gaps_out = 10,

	border_size = 1,

	col = {
	  active_border = colors.mauve,
	  inactive_border = colors.base,
	},

	resize_on_border = true,
	hover_icon_on_border = true,
    allow_tearing = false,
  },


  decoration = {
	  rounding = 20,
	  rounding_power = 7,

	  active_opacity = 1.0,
	  inactive_opacity = 0.99,

	  shadow = {
		  enabled = false
	  },

	  blur = {
		  enabled = true,
		  size = 3,
		  passes = 2,
		  noise = 0.08,
		  brightness = 1,
		  vibrancy = 0.25,
	  },
  }
})



hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
-- hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
-- hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
-- hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
-- hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
-- hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
-- hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
-- hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
-- hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
-- hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
-- hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
-- hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


hl.curve("macos_smooth", { type = "spring", mass = 1, stiffness = 85, dampening = 14, })
hl.curve("macos_soft", { type = "spring", mass = 1, stiffness = 70, dampening = 16, })
hl.curve("macos_snap", { type = "spring", mass = 1, stiffness = 110, dampening = 18, })

-- Keep global animations enabled.
hl.animation({ leaf = "global", enabled = true, speed = 1, spring = "macos_smooth", })
-- Window open/close/move.
-- "gnomed" tends to feel softer and less flashy than aggressive slide/popin.
hl.animation({ leaf = "windows", enabled = true, speed = 4.5, spring = "macos_smooth", style = "gnomed", })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "macos_smooth", style = "gnomed", })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, spring = "macos_soft", style = "gnomed", })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "macos_snap", })
-- Workspace movement.
-- For Niri/scrolling-layout style, keep this gentle.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, spring = "macos_soft", style = "slidevert", })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, spring = "macos_smooth", style = "slidevert", })
-- Layers: useful for launchers, panels, notifications, overlays.
hl.animation({ leaf = "layers", enabled = true, speed = 3.5, spring = "macos_smooth", style = "fade", })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, spring = "macos_soft", })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 2.5, spring = "macos_soft", })
-- Optional: faster border color transition.
hl.animation({ leaf = "border", enabled = true, speed = 2, spring = "macos_snap", })
