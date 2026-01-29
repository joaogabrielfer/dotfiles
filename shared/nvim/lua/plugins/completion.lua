-- Definimos o mapa de ícones no topo para ser usado de forma segura e rápida
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
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'L3MON4D3/LuaSnip',
      'onsails/lspkind.nvim',
    },
    version = '1.*',

    opts = {
      keymap = {
        preset = 'none',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
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
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        -- Aumentamos a prioridade dos snippets para resolver o problema do 'prints'
        -- providers = {
        --   snippets = {
        --     score_offset = 100, 
        --   }
        -- }
      },
      snippets = {
        preset = 'luasnip',
      },
      completion = {
        documentation = { auto_show = true, window = { border = 'rounded' } },
        menu = {
          border = 'rounded',
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  -- 1. Ícones de arquivos para o Path (usando mini.icons se disponível)
                  if ctx.source_name == "Path" then
                    local ok, mini_icons = pcall(require, "mini.icons")
                    if ok then
                      local icon, _ = mini_icons.get("file", ctx.label)
                      if icon then return icon .. ctx.icon_gap end
                    end
                  end
                  -- 2. Busca no nosso mapa local (evita o erro de symbolic ser nil)
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
      -- Inicializa o lspkind apenas como backup
      pcall(function()
        require('lspkind').init({ symbol_map = kind_icons })
      end)
      require('blink.cmp').setup(opts)
    end
  }
}
