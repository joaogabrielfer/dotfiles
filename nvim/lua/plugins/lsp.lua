return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = { 
                checkThirdParty = false,
                -- REMOVED manual library entries. 
                -- lazydev.nvim handles this dynamically, preventing duplicates.
              },
              completion = { callSnippet = "Replace" },
            },
          }
        },
        clangd = {},
        ts_ls = {},
        eslint = {},
        pyright = {},
        tailwindcss = {},
        html = {},
        arduino_language_server = {},
        cmake = {},
      }
    },
    config = function(_, opts)
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "clangd", "gopls" },
      })

      -- Get capabilities for blink.cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      for server, config in pairs(opts.servers) do
        -- Inject blink capabilities into the config
        config.capabilities = capabilities

        if not config.on_attach then
          config.on_attach = function(client, bufnr)
            if vim.bo[bufnr].filetype == "oil" then return end
            
            local function map_opts(description)
              return { buffer = bufnr, desc = description, remap = false }
            end

            -- Standard LSP Mappings
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts("LSP: Go to Definition"))
            vim.keymap.set("n", "K", vim.lsp.buf.hover, map_opts("LSP: Hover"))
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, map_opts("LSP: Go to Implementation"))
            vim.keymap.set("n", "gr", vim.lsp.buf.references, map_opts("LSP: Go to References"))
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, map_opts("LSP: Rename"))
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, map_opts("LSP: Code Action"))
            vim.keymap.set("n", "<leader>b", function() 
              vim.lsp.buf.format({ async = true }) 
            end, map_opts("LSP: Format"))
          end
        end

        -- FIX: Use the new native API to resolve the deprecation error
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end
  },
}
