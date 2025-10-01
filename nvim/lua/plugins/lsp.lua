return {
  {
    "mason-org/mason.nvim",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig"
    },
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim", "require", "opts" }
              },
            },
          }
        },
        ts_ls = {},
        eslint = {},
        pyright = {},
        clangd = {},
        tailwindcss = {},
        html = {},
        arduino_language_server = {}, -- Nome correto do servidor Arduino
        cmake = {},
      }
    },
    config = function(_, opts)
      -- Setup Mason primeiro
      require("mason").setup()

      -- Setup mason-lspconfig com ensure_installed
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "eslint",
          "pyright",
          "clangd",
          "cssls",
          "html",
          "arduino_language_server",
          "gopls",
          "hyprls",
        },
        automatic_installation = true, -- Instala automaticamente se não estiver presente
      })

      -- Configuração de diagnósticos
      vim.diagnostic.config({
        virtual_text = true,
        underline = true,
      })

      -- Configurar cada servidor usando a nova API
      for server, config in pairs(opts.servers) do
        -- Adicionar keybinds on_attach se não existir
        if not config.on_attach then
          config.on_attach = function(_, bufnr)
            vim.keymap.set("n", "<leader><Tab>", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP: Hover" })
            vim.keymap.set("n", "<leader>i", function()
              vim.diagnostic.open_float({ border = "rounded" })
            end, { buffer = bufnr, desc = "LSP: Diagnostic Float" })

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, "LSP: Go to Implementation")
            vim.keymap.set("n", "gr", vim.lsp.buf.references, "LSP: Go to References")
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename(), "LSP: Rename")
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
            vim.keymap.set("n", "<leader>b", function() vim.lsp.buf.format({ async = true }) end, "LSP: Format")
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, "LSP: Previous Diagnostic")
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, "LSP: Next Diagnostic")
          end
        end

        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end
  },
}
