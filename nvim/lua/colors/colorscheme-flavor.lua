if vim.g.theme_flavor == "peach" then
  require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      telescope = true,
      treesitter = true,
    },
    color_overrides = {
      mocha = {
          rosewater = "#f5e0dc", peach = "#fab387", yellow = "#f9e2af",
          orange = "#f5a97f", red = "#e8a2af", maroon = "#e8a2af",
          lavender = "#f5e0dc", blue = "#89b4fa", sky = "#89b4fa",
          sapphire = "#89b4fa", green = "#a6e3a1", teal = "#94e2d5",
          base = "#231e1e", mantle = "#1e1a1a", crust = "#191515",
          text = "#e6d9d4", subtext1 = "#d9c8c1", subtext0 = "#bfaea7",
          overlay2 = "#a6938d", overlay1 = "#8c7973", overlay0 = "#735f59",
          surface2 = "#594b45", surface1 = "#403631", surface0 = "#2b221d",
      },
    },
    custom_highlights = function(colors)
      return {
          -- Core UI
          StatusLine = { bg = colors.crust, fg = colors.peach },
          StatusLineNC = { bg = colors.crust, fg = colors.surface1 },
          WinSeparator = { fg = colors.peach, bold = true },
          -- >>>>>>>>> NEW: Make the mode indicator peach <<<<<<<<<<
          ModeMsg = { bg = colors.peach, fg = colors.crust, bold = true },

          -- >>>>>>>>> NEW: Make line numbers more visible <<<<<<<<<<
          LineNr = { fg = colors.subtext0 },
          CursorLineNr = { fg = colors.peach, bold = true },

          -- Editor
          Visual = { bg = colors.overlay0 },
          CursorLine = { bg = colors.surface0 },
          Search = { bg = colors.peach, fg = colors.crust },

          -- Plugins
          TelescopeBorder = { fg = colors.peach },
          TelescopePromptBorder = { fg = colors.peach },
          TelescopeSel = { bg = colors.surface1, fg = colors.sky, bold = true },
          CmpItemAbbrMatch = { fg = colors.peach, bold = true },
          CmpItemAbbrMatchFuzzy = { fg = colors.peach, bold = true },
          CmpSel = { bg = colors.surface1, bold = true },

          -- Diagnostics
          DiagnosticSignError = { fg = colors.red },
          DiagnosticSignWarn = { fg = colors.yellow },
          DiagnosticSignInfo = { fg = colors.sky },
          DiagnosticSignHint = { fg = colors.teal },
      }
    end,
  })
elseif vim.g.theme_flavor == "pink" then
  require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = false,
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      telescope = true,
      treesitter = true,
    },
    custom_highlights = function(colors)
      return {
        -- Core UI
        StatusLine = { bg = colors.crust, fg = colors.peach },
        StatusLineNC = { bg = colors.crust, fg = colors.surface1 },
        WinSeparator = { fg = colors.peach, bold = true },
        TabLineSel = { bg = colors.peach, fg = colors.crust },

        -- Editor
        Visual = { bg = colors.surface1 },
        CursorLine = { bg = colors.surface0 },
        Search = { bg = colors.peach, fg = colors.crust },

        -- Telescope
        TelescopeBorder = { fg = colors.peach },
        TelescopePromptBorder = { fg = colors.peach },
        TelescopeSel = { bg = colors.surface1 },

        -- Completion Menu
        CmpItemAbbrMatch = { fg = colors.peach, bold = true },
        CmpItemAbbrMatchFuzzy = { fg = colors.peach, bold = true },
        CmpSel = { bg = colors.surface1, bold = true },

        -- Diagnostics
        DiagnosticSignError = { fg = colors.red },
        DiagnosticSignWarn = { fg = colors.yellow },
        DiagnosticSignInfo = { fg = colors.sky },
        DiagnosticSignHint = { fg = colors.teal },
      }
      end,
      color_overrides = {
        mocha = {
          text = "#F4CDE9",
          subtext1 = "#DEBAD4",
          subtext0 = "#C8A6BE",
          overlay2 = "#B293A8",
          overlay1 = "#9C7F92",
          overlay0 = "#866C7D",
          surface2 = "#705867",
          surface1 = "#5A4551",
          surface0 = "#44313B",

          base = "#352939",
          mantle = "#211924",
          crust = "#1a1016",
        }
      },

  })
end
