local function gh(repo)
  return "https://github.com/" .. repo
end

-- Configure rustaceanvim before its ftplugin loads.
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        check = { command = "clippy" },
      },
    },
  },
}

-- Lifecycle build hooks for plugins installed or updated via vim.pack.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("dotfiles.pack", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    elseif name == "peek.nvim" and (kind == "install" or kind == "update") then
      local obj = vim.system({ "deno", "task", "--quiet", "build:fast" }, { cwd = ev.data.path })
      if kind == "install" then
        obj:wait()
      end
    end
  end,
})

vim.pack.add({
  -- UI & Theme
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("MeanderingProgrammer/render-markdown.nvim"),
  gh("toppair/peek.nvim"),

  -- Editor
  gh("folke/snacks.nvim"),
  gh("echasnovski/mini.nvim"),
  gh("stevearc/oil.nvim"),
  gh("folke/which-key.nvim"),

  -- Coding & LSP
  gh("rafamadriz/friendly-snippets"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  gh("folke/lazydev.nvim"),
  gh("mason-org/mason.nvim"),
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason-lspconfig.nvim"),
  gh("mrcjkb/rustaceanvim"),

  -- Treesitter
  {
    src = gh("nvim-treesitter/nvim-treesitter"),
    version = "cf12346a3414fa1b06af75c79faebe7f76df080a",
  },

  -- Tools
  gh("tpope/vim-fugitive"),
  gh("lewis6991/gitsigns.nvim"),
}, { confirm = false })

require("plugins.editor")
require("plugins.coding")
require("plugins.treesitter")
require("plugins.tools")
require("plugins.ui")
