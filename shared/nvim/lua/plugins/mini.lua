return {
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      -- ====================================================
      -- 1. MINI.STATUSLINE
      -- ====================================================
      local function set_statusline_colors()
        vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal",  { fg = "#11111b", bg = "#fab387", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert",  { fg = "#11111b", bg = "#a6e3a1", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual",  { fg = "#11111b", bg = "#fac3b7", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = "#11111b", bg = "#eba0ac", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = "#11111b", bg = "#f38ba8", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineInactive",    { fg = "#6c7086", bg = "#181825" })
      end

      set_statusline_colors()

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          set_statusline_colors()
        end,
      })

      require("mini.statusline").setup({ use_icons = true })

      -- ====================================================
      -- 2. MINI.PAIRS
      -- ====================================================
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
      MiniPairs.unmap("i", '"', '"')
      -- ====================================================
      -- 3. MINI.INDENTSCOPE
      -- ====================================================
      require('mini.indentscope').setup({
        draw = {
          -- Desativa a animação de desenhar a linha
          animation = require('mini.indentscope').gen_animation.none(),
        },
      })

      -- ====================================================
      -- 4. OUTROS MÓDULOS (Setup Padrão)
      -- ====================================================
      require("mini.surround").setup()
      require('mini.align').setup()
      require('mini.ai').setup()
      require('mini.trailspace').setup()
      require('mini.move').setup()

    end
  }
}
