-- keymaps.lua - Todas as keybinds organizadas por categoria

local setkey = vim.keymap.set

-- ================================
-- KEYBINDS EXISTENTES
-- ================================

-- File Explorer
setkey("n", "-", vim.cmd.Oil, { desc = "Open Oil file explorer" })
setkey("n", "_", "<CMD>:Oil .<CR>", { desc = "Open Oil file explorer in pwd" })

-- Lua execution
setkey("n", "<leader>x", ":.lua<CR>", { desc = "Execute current line as Lua" })
setkey("v", "<leader>x", ":lua<CR>", { desc = "Execute selection as Lua" })
setkey("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Source current file" })

-- Save
setkey("n", "<leader>w", "<cmd>w!<CR>", { desc = "Save file" })

-- Quit
setkey("n", "<leader>q", "<C-w>q", { desc = "Close current window" })

-- Insert mode escape
setkey("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- Move lines (visual mode)
setkey("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
setkey("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Move lines (normal mode)
setkey("n", "<A-J>", "<S-v>:m '>+1<CR>gv=gv<S-v>", { silent = true, desc = "Move line down" })
setkey("n", "<A-K>", "<S-v>:m '<-2<CR>gv=gv<S-v>", { silent = true, desc = "Move line up" })

-- Scroll and center
setkey("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
setkey("n", "<C-g>", "<C-g>zz", { desc = "Scroll up and center" })

-- Delete to void register
setkey("n", "<leader>p", "\"_dP", { desc = "Paste without yanking" })
setkey("v", "<leader>p", "\"_dP", { desc = "Paste without yanking" })
setkey("n", "<leader>d", "\"_d", { desc = "Delete to void register" })
setkey("v", "<leader>d", "\"_d", { desc = "Delete selection to void register" })

-- Telescope
setkey("n", "<leader>f", require("telescope.builtin").find_files)
setkey("n", "<leader>gg", require("telescope.builtin").live_grep)
setkey("n", "<leader>gh", require("telescope.builtin").help_tags)
setkey("n", "<leader>en", function()
  require("telescope.builtin").find_files {
    cwd = vim.fn.stdpath("config")
  }
end)
setkey("n", "<leader>ep", function()
  require("telescope.builtin").find_files {
    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
  }
end)

-- Better indenting in visual mode
setkey("v", "<", "<gv", { desc = "Indent left and reselect" })
setkey("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Clear search highlights
setkey("n", "<leader>/", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- LSP
setkey("n", "<leader><Tab>", vim.lsp.buf.hover)
setkey("n", "<leader>i", function()
  vim.diagnostic.open_float({ border = "rounded" })
end)

setkey("n", "gd", "<cmd>vim.lsp.buf.definition()<CR>")
setkey("n", "gD", "<cmd>vim.lsp.buf.declaration()<CR>")
setkey("n", "gi", "<cmd>vim.lsp.buf.implementation()<CR>")
setkey("n", "gr", "<cmd>vim.lsp.buf.references()<CR>")
setkey("n", "<leader>ca", "<cmd>vim.lsp.buf.code_action()<CR>")
setkey("n", "<leader>bf", function() vim.lsp.buf.format({ async = true }) end)
setkey("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")

-- Switch .h and .c files
setkey("n", "<leader>s", function()
  local full_path = vim.api.nvim_buf_get_name(0)
  local dir, name, extension = full_path:match("(.-)([^/]+)%.([^%.]+)$")

  if not dir or not name or not extension then return end

  if extension == "h" then
    local target = dir .. name .. ".c"
    vim.cmd.e(target)
  elseif extension == "c" then
    local target = dir .. name .. ".h"
    vim.cmd.e(target)
  end
end, { desc = "Switch between .h and .c files" })

-- Copy entire file
setkey("n", "<C-a>", "ggVGy")

-- Write bash sheabang
setkey("n", "<leader>bs", function ()
  local lines = {"#!/usr/bin/env bash", "", "set -xe"}
  vim.api.nvim_buf_set_lines(0, 0, 0, true, lines)
  vim.cmd("!chmod +x %")
end)

