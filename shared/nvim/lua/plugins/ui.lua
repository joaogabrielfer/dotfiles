-- render-markdown (deferred until first markdown/Avante buffer)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.render-markdown", { clear = true }),
  pattern = { "markdown", "Avante" },
  once = true,
  callback = function()
    require("render-markdown").setup({
      latex = { enabled = false },
    })
  end,
})

-- peek.nvim (initialized lazily on first command invocation)
local peek_ready = false
local function ensure_peek()
  local peek = require("peek")
  if not peek_ready then
    peek.setup({ app = "browser" })
    peek_ready = true
  end
  return peek
end

vim.api.nvim_create_user_command("PeekOpen", function()
  ensure_peek().open()
end, { desc = "Open Markdown preview in browser" })

vim.api.nvim_create_user_command("PeekClose", function()
  ensure_peek().close()
end, { desc = "Close Markdown preview" })
