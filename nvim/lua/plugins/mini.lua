return {
  {
    "echasnovski/mini.statusline",
    enabled = true,
    config = function()
      -- Define a function that contains our desired colors.
      -- This makes the logic clean and reusable.
      local function set_statusline_colors()
        vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal",  { fg = "#11111b", bg = "#fab387", bold = true }) -- bg=peach
        vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert",  { fg = "#11111b", bg = "#a6e3a1", bold = true }) -- bg=green
        vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual",  { fg = "#11111b", bg = "#fac3b7", bold = true }) -- bg=sky
        vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = "#11111b", bg = "#eba0ac", bold = true }) -- bg=maroon
        vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = "#11111b", bg = "#f38ba8", bold = true }) -- bg=red
        vim.api.nvim_set_hl(0, "MiniStatuslineInactive",    { fg = "#6c7086", bg = "#181825" })     -- fg=overlay0, bg=mantle
      end

      -- Apply the colors immediately when this plugin loads.
      set_statusline_colors()

      -- This is the key: Create a new autocommand that will re-apply our
      -- custom colors every single time a colorscheme is loaded.
      -- This ensures our settings always have the final say.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          set_statusline_colors()
        end,
      })

      -- Set up mini.statusline itself.
      require("mini.statusline").setup({
        use_icons = true,
      })
    end,
  },
  {
    "echasnovski/mini.comment",
    config = function()
      require("mini.comment").setup()
    end,
  },
  {
    "echasnovski/mini.pairs",
    config = function()
      require("mini.pairs").setup({
        pairs = {
          ['('] = { close = ')', neigh_pattern = '[^\\].' },
          ['['] = { close = ']', neigh_pattern = '[^\\].' },
          ['{'] = { close = '}', neigh_pattern = '[^\\].' },
        },
        modes = { insert = true, command = false, terminal = false },
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_ts = { 'string' },
        skip_unbalanced = true,
        markdown = false,
      })
    end,
  },
  {
    "echasnovski/mini.surround",
    config = function()
      require("mini.surround").setup()
    end,
  },
}
