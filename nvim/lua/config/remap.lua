-- keymaps.lua - Todas as keybinds organizadas por categoria

local opts = { noremap = true, silent = true }

-- ================================
-- KEYBINDS EXISTENTES
-- ================================

-- File Explorer
vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open Oil file explorer" })
vim.keymap.set("n", "_", "<CMD>:Oil .<CR>", { desc = "Open Oil file explorer in pwd" })

-- Lua execution
vim.keymap.set("n", "<leader>x", ":.lua<CR>", { desc = "Execute current line as Lua" })
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Execute selection as Lua" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Source current file" })

-- Save
vim.keymap.set("n", "<leader>w", "<cmd>w!<CR>", { desc = "Save file" })

-- Quit
vim.keymap.set("n", "<leader>q", "<C-w>q", { desc = "Close current window" })

-- Save and quit
vim.keymap.set("n", "<leader>s", "<cmd>wq<CR>", { desc = "Save file and quit window" })

-- Insert mode escape
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- Move lines (visual mode)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Move lines (normal mode)
vim.keymap.set("n", "<A-J>", "<S-v>:m '>+1<CR>gv=gv<S-v>", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<A-K>", "<S-v>:m '<-2<CR>gv=gv<S-v>", { silent = true, desc = "Move line up" })

-- Scroll and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-g>", "<C-g>zz", { desc = "Scroll up and center" })

-- Delete to void register
vim.keymap.set("n", "<leader>p", "\"_dP", { desc = "Paste without yanking" })
vim.keymap.set("v", "<leader>p", "\"_dP", { desc = "Paste without yanking" })
vim.keymap.set("n", "<leader>d", "\"_d", { desc = "Delete to void register" })
vim.keymap.set("v", "<leader>d", "\"_d", { desc = "Delete selection to void register" })

-- Telescope
vim.keymap.set("n", "<leader>f", require("telescope.builtin").find_files)
vim.keymap.set("n", "<leader>gg", require("telescope.builtin").live_grep)
vim.keymap.set("n", "<leader>h", require("telescope.builtin").help_tags)
vim.keymap.set("n", "<leader>en", function()
  require("telescope.builtin").find_files {
    cwd = vim.fn.stdpath("config")
  }
end)
vim.keymap.set("n", "<leader>ep", function()
  require("telescope.builtin").find_files {
    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
  }
end)

-- Chmod
vim.keymap.set("n", "<leader>c", "<cmd>!chmod +x %<CR>", { silent = true })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Clear search highlights
vim.keymap.set("n", "<leader>/", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- LSP
vim.keymap.set("n", "<leader><Tab>", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>i", function()
  vim.diagnostic.open_float({ border = "rounded" })
end)

vim.keymap.set("n", "gd", "<cmd>vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gD", "<cmd>vim.lsp.buf.declaration()<CR>")
vim.keymap.set("n", "gi", "<cmd>vim.lsp.buf.implementation()<CR>")
vim.keymap.set("n", "gr", "<cmd>vim.lsp.buf.references()<CR>")
vim.keymap.set("n", "<leader>ca", "<cmd>vim.lsp.buf.code_action()<CR>")
vim.keymap.set("n", "<leader>b", function() vim.lsp.buf.format({ async = true }) end)
vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")

