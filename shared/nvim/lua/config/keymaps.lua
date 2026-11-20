local map = vim.keymap.set

vim.api.nvim_create_user_command("Keymaps", function()
  Snacks.picker.keymaps()
end, { desc = "Search configured keymaps" })

-- Write and quit
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
map("n", "<leader>q", "<C-w>q", { desc = "Close window" })
map("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- Scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Pasting and yanking
map("n", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "x" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Moving
map("x", "<M-j>", ":move '>+1<cr>gv=gv", { silent = true, desc = "Move selection down" })
map("x", "<M-k>", ":move '<-2<cr>gv=gv", { silent = true, desc = "Move selection up" })
map("x", "<M-h>", "<gv", { silent = true, desc = "Indent left" })
map("x", "<M-l>", ">gv", { silent = true, desc = "Indent right" })

-- Executing lua
map("n", "<leader>x", ":.lua<cr>", { desc = "Execute Lua line" })
map("x", "<leader>x", ":lua<cr>", { desc = "Execute Lua selection" })
map("n", "<leader><leader>x", "<cmd>source %<cr>", { desc = "Source current file" })

-- LSP
map("n", "<leader><Tab>", vim.lsp.buf.hover, { desc = "LSP hover" })
map("n", "<leader>i", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "gd", vim.lsp.buf.definition, { desc = "LSP definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP declaration" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
map("n", "gr", vim.lsp.buf.references, { desc = "LSP references" })
map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>cf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format buffer" })
map("n", "<leader><A-i>", function()
  vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.WARN } })
end, { desc = "Diagnostics to quickfix" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -vim.v.count1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = vim.v.count1, float = true })
end, { desc = "Next diagnostic" })
local function quickfix(command, boundary)
  return function()
    if not pcall(vim.cmd, command) then
      vim.notify(boundary, vim.log.levels.INFO)
    end
  end
end

-- Quickfix stuff
local function toggle_quickfix()
  local open = vim.iter(vim.fn.getwininfo()):any(function(window)
    return window.quickfix == 1
  end)
  if open then
    vim.cmd.cclose()
  elseif #vim.fn.getqflist() > 0 then
    vim.cmd.copen()
  else
    vim.notify("Quickfix is empty", vim.log.levels.INFO)
  end
end
map("n", "<A-p>", quickfix("cprevious", "Start of quickfix"), { desc = "Previous quickfix item" })
map("n", "<A-n>", quickfix("cnext", "End of quickfix"), { desc = "Next quickfix item" })
map("n", "<leader>o", toggle_quickfix, { desc = "Toggle quickfix" })
map("n", "<A-i>", function()
  vim.cmd.write()
  vim.cmd.cfirst()
end, { desc = "Write and open quickfix" })

-- Inline LSP things
map("n", "<leader>uv", function()
  local enabled = vim.diagnostic.config().virtual_lines == true
  vim.diagnostic.config({ virtual_lines = not enabled })
end, { desc = "Toggle diagnostic lines" })

map("n", "<leader>uh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end, { desc = "Toggle inlay hints" })

map("n", "<leader>ul", function()
  local enabled = vim.lsp.codelens.is_enabled({ bufnr = 0 })
  vim.lsp.codelens.enable(not enabled, { bufnr = 0 })
end, { desc = "Toggle code lens" })


-- Switch .c and .h files
local function switch_c_source()
  local path = vim.api.nvim_buf_get_name(0)
  local stem, extension = path:match("^(.*)%.([^./]+)$")
  if not stem or (extension ~= "h" and extension ~= "c") then
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(stem .. (extension == "h" and ".c" or ".h")))
end
map("n", "<leader>cs", switch_c_source, { desc = "Switch C source/header" })

-- Yank entire file
map("n", "<leader>ya", "<cmd>%yank +<cr>", { desc = "Yank entire file" })

-- Bash
map("n", "<leader>xs", function()
  vim.api.nvim_buf_set_lines(0, 0, 0, true, { "#!/usr/bin/env bash", "", "set -xe" })
  vim.fn.system({ "chmod", "+x", vim.api.nvim_buf_get_name(0) })
end, { desc = "Add shell template" })
map("n", "<leader>xx", function()
  vim.fn.system({ "chmod", "+x", vim.api.nvim_buf_get_name(0) })
end, { desc = "Make file executable" })

-- Terminal groups & unified pane navigation
local terminal = require("config.terminal")

map("n", "<C-t>", function()
  local count = vim.v.count
  terminal.toggle(count > 0 and count or nil)
end, { silent = true, desc = "Toggle terminal group (count = slot)" })

map("t", "<C-t>", function()
  terminal.toggle(nil)
end, { silent = true, desc = "Hide active terminal" })

map({ "n", "t" }, "<C-S-t>", function()
  terminal.context_shift_t()
end, { silent = true, desc = "Split terminal pane or toggle float" })

map("n", "<leader>tt", function()
  terminal.pick_groups()
end, { silent = true, desc = "Manage terminal groups" })

for _, dir in ipairs({
  { key = "h", dir = "h", name = "left" },
  { key = "j", dir = "j", name = "down" },
  { key = "k", dir = "k", name = "up" },
  { key = "l", dir = "l", name = "right" },
}) do
  map("n", "<C-M-" .. dir.key .. ">", function()
    terminal.navigate(dir.dir, false)
  end, { silent = true, desc = "Move to " .. dir.name .. " pane" })
  map("t", "<C-M-" .. dir.key .. ">", function()
    terminal.navigate(dir.dir, true)
  end, { silent = true, desc = "Move to " .. dir.name .. " pane" })
end
