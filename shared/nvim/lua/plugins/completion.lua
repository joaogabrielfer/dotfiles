-- Definição dos ícones
local kind_icons = {
  Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
  Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
  Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
  Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
  File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
  Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
  TypeParameter = "󰉿",
}

return {
  -- 1. Plugin de Compatibilidade (Definido separadamente para garantir instalação)
  {
    'saghen/blink.compat',
    version = '*',
    lazy = true,
    opts = {},
  },

  -- 2. Blink CMP Principal
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'L3MON4D3/LuaSnip',
      'onsails/lspkind.nvim',
      'saghen/blink.compat', -- Referência à dependência acima
    },
    
    -- IMPORTANTE: Use v0.*. A versão 1.* não existe ou é instável para compatibilidade
    version = 'v0.*', 

    opts = {
      keymap = {
        preset = 'none',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<A-.>'] = { 'snippet_forward', 'fallback' },
        ['<A-,>'] = { 'snippet_backward', 'fallback' },
        ['<Esc>'] = { 'hide', 'fallback' },
      },
      
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },

      sources = {
        -- Adicione 'obsidian' aqui
        default = { 'lsp', 'path', 'snippets', 'buffer', 'obsidian' },
        
        providers = {
          obsidian = {
            name = 'obsidian',
            module = 'blink.compat.source',
            score_offset = 3,
          }
        }
      },

      snippets = {
        preset = 'luasnip',
      },

      completion = {
        documentation = { auto_show = true, window = { border = 'rounded' } },
        ghost_text = { enabled = true },
        list = {
          selection = {
            preselect = false,
            auto_insert = false 
          },
        },
        menu = {
          border = 'rounded',
          draw = {
            columns = {
              { "kind_icon" },
              { "label",    "label_description", gap = 1 },
              { "kind" },
            },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  if ctx.source_name == "Path" then
                    local ok, mini_icons = pcall(require, "mini.icons")
                    if ok then
                      local icon, _ = mini_icons.get("file", ctx.label)
                      if icon then return icon .. ctx.icon_gap end
                    end
                  end
                  return (kind_icons[ctx.kind] or ctx.kind_icon or "󰔚") .. ctx.icon_gap
                end,
                highlight = function(ctx) return ctx.kind_hl end,
              },
              kind = {
                text = function(ctx) return " " .. ctx.kind .. " " end,
                highlight = "Comment",
              },
              label_description = { highlight = "Comment" }
            }
          },
        },
      },
    },
    
    config = function(_, opts)
      pcall(function()
        require('lspkind').init({ symbol_map = kind_icons })
      end)
      require('blink.cmp').setup(opts)
    end
  }
}
