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

-- Move lines (normal mode)
-- in Alt hjkl in mini.lua

-- Better indenting in visual mode

setkey("v", "<M-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Mover bloco para baixo" })
setkey("v", "<M-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Mover bloco para cima" })
setkey("v", "<M-h>", "<gv", { silent = true, desc = "Indentar para esquerda" })
setkey("v", "<M-l>", ">gv", { silent = true, desc = "Indentar para direita" })

-- LSP
setkey("n", "<leader><Tab>", vim.lsp.buf.hover)
setkey("n", "<leader>i", function()
  vim.diagnostic.open_float({ border = "rounded" })
end, {desc = "Open diagnostic window" })

setkey("n", "gd", "<cmd>vim.lsp.buf.definition()<CR>")
setkey("n", "gD", "<cmd>vim.lsp.buf.declaration()<CR>")
setkey("n", "gi", "<cmd>vim.lsp.buf.implementation()<CR>")
setkey("n", "gr", "<cmd>vim.lsp.buf.references()<CR>")
setkey("n", "<leader>ca", "<cmd>vim.lsp.buf.code_action()<CR>")
setkey("n", "<leader>bf", function() vim.lsp.buf.format({ async = true }) end)
setkey("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")

-- Pega apenas Erros e Warnings de todos os arquivos abertos no workspace
setkey("n", "<leader>I", function()
  vim.diagnostic.setqflist({
    severity = { min = vim.diagnostic.severity.WARN }
  })
end, { desc = "LSP Erros/Avisos na Quickfix" })

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

-- chmod file
setkey("n", "<leader>ch", "<cmd>!chmod +x %<CR>", {desc = "Chmod +x this file" })

-- open tmux window with file
setkey('n', '<C-f>', function()
  local target_path = ""

  if vim.bo.filetype == "oil" then
    local ok, oil = pcall(require, "oil")
    if ok then
      local dir = oil.get_current_dir()
      local entry = oil.get_cursor_entry()
      if entry and dir then
        target_path = dir .. entry.name
      end
    end

  else
    local cfile = vim.fn.expand('<cfile>')

    if vim.bo.filetype == "rust" then
      local clean_cfile = cfile:gsub(";", "")

      local found_rs = vim.fn.findfile(clean_cfile .. ".rs")
      local found_mod = vim.fn.findfile(clean_cfile .. "/mod.rs")

      if found_rs ~= "" then
        target_path = found_rs
      elseif found_mod ~= "" then
        target_path = found_mod
      end
    end

    if target_path == "" then
      local found_file = vim.fn.findfile(cfile)
      local found_dir = vim.fn.finddir(cfile)

      if found_file ~= "" then
        target_path = found_file
      elseif found_dir ~= "" then
        target_path = found_dir
      else
        target_path = cfile
      end
    end

    target_path = vim.fn.fnamemodify(target_path, ":p")
  end

  if target_path == "" or not vim.uv.fs_stat(target_path) then
    vim.notify("Caminho inválido ou arquivo não encontrado: " .. tostring(target_path), vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(target_path, ":t")

  local escaped_filename = filename:gsub("'", "'\\''")
  local escaped_path = target_path:gsub("'", "'\\''")

  local tmux_cmd = string.format("tmux neww -c '#{pane_current_path}' -n '%s' nvim '%s'", escaped_filename, escaped_path)

  vim.fn.system(tmux_cmd)

end, { desc = "Abrir arquivo sob cursor no Tmux (Nova Aba)" })

-- quickfix list
setkey("n", "<leader>o", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_exists = true
      break
    end
  end

  if qf_exists then
    vim.cmd("cclose")
  else
    if not vim.tbl_isempty(vim.fn.getqflist()) then
      vim.cmd("copen")
    else
      vim.notify("Quickfix está vazia!", vim.log.levels.WARN)
    end
  end
end, { desc = "Toggle Quickfix" })

setkey("n", "<leader>bh", function()
  -- Pega informações de todos os buffers listados
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })

  -- Ordena do mais recente para o mais antigo
  table.sort(bufs, function(a, b) return a.lastused > b.lastused end)

  local qf_list = {}
  for _, buf in ipairs(bufs) do
    if buf.name ~= "" then
      table.insert(qf_list, {
        bufnr = buf.bufnr,
        lnum = buf.lnum, -- Lembra a linha exata que você estava no arquivo!
        text = "Buffer: " .. vim.fn.fnamemodify(buf.name, ":t") -- Mostra só o nome do arquivo
      })
    end
  end

  -- Substitui a Quickfix atual por essa lista e abre
  vim.fn.setqflist(qf_list, 'r')
  vim.fn.setqflist({}, 'a', { title = 'Histórico de Buffers' })
  vim.cmd("copen")
end, { desc = "Histórico de Buffers na Quickfix" })

setkey("n", "<A-n>", function()
  local ok, _ = pcall(vim.cmd, "cnext")
  if not ok then vim.notify("Fim da Quickfix List", vim.log.levels.INFO) end
end, { desc = "Próximo item da Quickfix" })

setkey("n", "<A-p>", function()
local ok, _ = pcall(vim.cmd, "cprev")
if not ok then vim.notify("Início da Quickfix List", vim.log.levels.INFO) end
end, { desc = "Item anterior da Quickfix" })
