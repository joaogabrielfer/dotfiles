-- keymaps.lua - Todas as keybinds organizadas por categoria

local opts = { noremap = true, silent = true }

-- ================================
-- KEYBINDS EXISTENTES
-- ================================

-- File Explorer
vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open Oil file explorer" })

-- Lua execution
vim.keymap.set("n", "<leader>x", ":.lua<CR>", { desc = "Execute current line as Lua" })
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Execute selection as Lua" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Source current file" })

-- Copy pwd
vim.keymap.set('n', '<leader>[', function()
  local current_dir = vim.fn.getcwd()
  vim.fn.setreg('+', current_dir)
  vim.notify("Copied PWD: " .. current_dir)
end, { desc = "Copy current working directory" })

-- Save
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

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

-- LSP
vim.keymap.set("n", "<leader><Tab>", vim.lsp.buf.hover, opts)
vim.keymap.set("n", "<leader>i", function()
  vim.diagnostic.open_float({
    border = "rounded",
  })
end, { desc = "Show diagnostic float" })
-- ================================
-- ADICIONAIS ÚTEIS
-- ================================

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Clear search highlights
  vim.keymap.set("n", "<leader>/", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })



-- ================================
-- LSP KEYBINDS COMPLETAS
-- ================================

-- Define função para keybinds do LSP
local function setup_lsp_keymaps(bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Suas existentes
  map("n", "<leader><Tab>", vim.lsp.buf.hover, "LSP: Hover Documentation")
  map("n", "<leader>i", vim.diagnostic.open_float, "LSP: Show Diagnostic")

  -- Adicionais úteis
  map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
  map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
  map("n", "gi", vim.lsp.buf.implementation, "LSP: Go to Implementation")
  map("n", "gr", vim.lsp.buf.references, "LSP: Go to References")
  map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "LSP: Format")
  map("n", "[d", vim.diagnostic.goto_prev, "LSP: Previous Diagnostic")
  map("n", "]d", vim.diagnostic.goto_next, "LSP: Next Diagnostic")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.keymap.set('n', '<F5>', function()
      vim.cmd('silent !cd build && cmake --build . --config Release')
      vim.cmd('redraw!')
    end, { desc = 'Build project', buffer = true })

    vim.keymap.set('n', '<F6>', function()
      vim.cmd('silent !cd build && ./Release/LearnOpenGL.exe')
      vim.cmd('redraw!')
    end, { desc = 'Run project', buffer = true })
  end,
})-- Exportar função para usar no setup do LSP
return {
  setup_lsp_keymaps = setup_lsp_keymaps
}

