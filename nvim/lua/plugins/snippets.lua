return {
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = 'make install_jsregexp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local fmt = require("luasnip.extras.fmt").fmt
      local rep = require("luasnip.extras").rep

      -- Configurações
      ls.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
        -- Importante para blink.cmp
        store_selection_keys = "<Tab>",
      })

      -- Carrega snippets do friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Snippets para Go
      ls.add_snippets("go", {
        s("iferr", {
          t({"if err != nil {", "\t"}),
          i(1, "log.Fatal(err)"),
          t({"", "}"})
        })
      })

      ls.add_snippets("all", {
        s("ternary", {
          i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
        })
      })

      -- Snippets para C com prioridade maior
      ls.add_snippets("c", {
        s({
          trig = "prints",
          priority = 1000,
        }, fmt([[printf("%{}", {});]], {
          i(1, "d"),
          i(2, "var")
        })),

        s({
          trig = "printvar",
          priority = 1000,
        }, fmt([[printf("{} = %{}", {});]], {
          i(1, "variable"),
          i(2, "d"),
          rep(1)
        })),
      })
    end,
  }
}
