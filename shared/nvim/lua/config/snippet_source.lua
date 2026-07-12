local Source = {}
Source.__index = Source
local gpl_cache

function Source.new()
  return setmetatable({}, Source)
end

local function read_gpl()
  if gpl_cache then
    return gpl_cache
  end
  local path = vim.fn.stdpath("config") .. "/snippets/gpl-3.0.txt"
  local ok, lines = pcall(vim.fn.readfile, path)
  gpl_cache = ok and table.concat(lines, "\n") or ""
  return gpl_cache
end

function Source:get_completions(_, callback)
  local items = {
    {
      label = "ternary",
      detail = "condition ? then : else",
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = "${1:condition} ? ${2:then} : ${3:else}",
    },
  }

  if vim.bo.filetype == "go" then
    table.insert(items, {
      label = "iferr",
      detail = "Go error guard",
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = "if err != nil {\n\t${1:log.Fatal(err)}\n}",
    })
  end

  local license = read_gpl()
  if license ~= "" then
    table.insert(items, {
      label = "gpl",
      detail = "GNU General Public License v3",
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = license,
    })
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

return Source
