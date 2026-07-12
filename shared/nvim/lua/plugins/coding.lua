return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "none",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<A-.>"] = { "snippet_forward", "fallback" },
        ["<A-,>"] = { "snippet_backward", "fallback" },
        ["<Esc>"] = { "hide", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "dotfiles" },
        providers = {
          dotfiles = {
            name = "Dotfiles",
            module = "config.snippet_source",
            score_offset = 2,
          },
        },
      },
      completion = {
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
        list = {
          selection = { preselect = false, auto_insert = false },
        },
        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
            components = {
              kind_icon = {
                text = function(context)
                  if context.source_name == "Path" then
                    local icon = require("mini.icons").get("file", context.label)
                    if icon then
                      return icon .. context.icon_gap
                    end
                  end
                  return context.kind_icon .. context.icon_gap
                end,
              },
            },
          },
        },
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "lazy.nvim", words = { "require%([\"']lazy" } },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
    config = function()
      local lsp = require("config.lsp")
      require("mason-lspconfig").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(lsp.mason_servers), { "rust_analyzer" }),
        automatic_enable = false,
      })
      lsp.setup()
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = false,
    lazy = false,
    init = function()
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
    end,
  },
}
