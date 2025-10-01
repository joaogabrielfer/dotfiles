return {
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    version = '1.*',

    opts = {
      keymap = {
        preset = 'default',
        ["<S-Tab>"] = { 'select_prev', 'fallback_to_mappings' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      snippets = {
        preset = 'luasnip',
      },
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },
      completion = {
        documentation = { auto_show = true },
        list = {
          selection = { preselect = false, auto_insert = true },
        },
      },
    }
  }
}
