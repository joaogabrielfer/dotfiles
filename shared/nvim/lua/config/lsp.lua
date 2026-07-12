local M = {}

M.servers = {
  "arduino_language_server",
  "clangd",
  "eslint",
  "gleam",
  "gopls",
  "html",
  "lua_ls",
  "pyright",
  "qmlls",
  "tailwindcss",
  "ts_ls",
}

M.mason_servers = vim.tbl_filter(function(server)
  return server ~= "gleam"
end, M.servers)

function M.setup()
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false },
        completion = { callSnippet = "Replace" },
      },
    },
  })

  vim.lsp.config("qmlls", {
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/qmlls" },
    on_attach = function(client)
      client.server_capabilities.semanticTokensProvider = nil
    end,
  })

  vim.lsp.enable(M.servers)
end

return M
