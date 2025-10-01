return {
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = 'make install_jsregexp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    config = function()
      -- Require luasnip and its components
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node

      -- Load snippets from friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Define and add your custom Go snippets directly
      ls.add_snippets("go", {
        -- Snippet for standard error handling
        s("iferr", t({
          "if err != nil {",
          "\tlog.Fatal(err)",
          "}"
        }))
      })
    end,
  }
}
