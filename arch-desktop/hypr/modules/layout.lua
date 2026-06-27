hl.config({ general = { layout = "scrolling" } })

hl.config({
	dwindle = {
		preserve_split = true,     -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		-- Niri: default-column-width { proportion 0.5; }
		column_width = 0.5,

		-- Niri:
		-- preset-column-widths {
		--   proportion 0.33333
		--   proportion 0.5
		--   proportion 0.66667
		-- }
		explicit_column_widths = "0.33333, 0.5, 0.66667, 0.75, 1.0",

		-- Niri-like: columns grow horizontally.
		direction = "right",

		-- Closer to Niri's `center-focused-column "never"`:
		-- 0 = center, 1 = fit. Fit avoids always centering.
		focus_fit_method = 1,

		-- Keep focused column visible when focus changes.
		follow_focus = true,

		-- How much of a column can remain visible before Hyprland scrolls it into view.
		follow_min_visible = 0.4,

		-- Let focus wrap from first/last column.
		wrap_focus = false,
		wrap_swapcol = false,

		-- Similar to Niri's behavior where one column can fill the workspace.
		fullscreen_on_one_column = true,
	},
})
