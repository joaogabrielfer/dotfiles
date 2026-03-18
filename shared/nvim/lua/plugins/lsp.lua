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
        -- ❌ REMOVIDO: rust_analyzer = {},
        -- Deixamos o rustaceanvim cuidar dele exclusivamente!
      }
    },
    config = function(_, opts)
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "clangd", "gopls" },
      })

      -- Pega capacidades para o blink.cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      for server, config in pairs(opts.servers) do
        -- Injeta capacidades no config
        config.capabilities = capabilities

        if not config.on_attach then
          config.on_attach = function(client, bufnr)
            if vim.bo[bufnr].filetype == "oil" then return end
            
            local function map_opts(description)
              return { buffer = bufnr, desc = description, remap = false }
            end

            -- Atalhos padrão do LSP
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

        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end
  },
{
    'mrcjkb/rustaceanvim',
    version = '^5', -- Use ^5 se estiver no Neovim 0.10, ou deixe '*' para a última
    lazy = false,   -- CRUCIAL: Tem que ser false e NÃO pode ter 'ft'
    init = function()
      -- Transformamos a configuração em uma função. 
      -- Assim, ela só executa no momento exato em que você abrir um arquivo .rs
      vim.g.rustaceanvim = function()
        
        -- Carrega o blink.cmp com segurança sem quebrar o startup do Neovim
        local capabilities = {}
        local ok, blink = pcall(require, "blink.cmp")
        if ok then
          capabilities = blink.get_lsp_capabilities()
        else
          capabilities = vim.lsp.protocol.make_client_capabilities()
        end

        return {
          server = {
            capabilities = capabilities,
            
            on_attach = function(client, bufnr)
              local function map_opts(description)
                return { buffer = bufnr, desc = description, remap = false }
              end

              -- Mapeamentos padrão
              vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts("LSP: Go to Definition"))
              vim.keymap.set("n", "K", vim.lsp.buf.hover, map_opts("LSP: Hover"))
              vim.keymap.set("n", "gi", vim.lsp.buf.implementation, map_opts("LSP: Go to Implementation"))
              vim.keymap.set("n", "gr", vim.lsp.buf.references, map_opts("LSP: Go to References"))
              vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, map_opts("LSP: Rename"))
              
              -- Code Actions maravilhosas do Rust
              vim.keymap.set("n", "<leader>ca", function() 
                vim.cmd.RustLsp('codeAction') 
              end, map_opts("Rust: Code Action"))
              
              vim.keymap.set("n", "<leader>b", function() 
                vim.lsp.buf.format({ async = true }) 
              end, map_opts("LSP: Format"))
            end,

            default_settings = {
              ['rust-analyzer'] = {
                cargo = {
                  allFeatures = true,
                },
                check= {
                  command = "clippy",
                },
              },
            },
          },
        }
      end
    end
  }
}
