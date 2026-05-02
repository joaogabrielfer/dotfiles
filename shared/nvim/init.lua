--bootstrap do lazyvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("config.lazy")
require("config.remap")
require 'nvim-treesitter.install'.compilers = { "clang" }
require("luasnip.loaders.from_vscode").lazy_load()

vim.g.vim_markdown_frontmatter = 1
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.md",
  callback = function()
    -- Substitua pelo caminho do seu Vault
    if vim.fn.expand("%:p"):find(vim.fn.expand("~") .. "/personal/notas/") then
      vim.cmd("RenderMarkdown disable")
    else
      vim.cmd("RenderMarkdown enable")
    end
  end,
})

vim.opt.completeopt = { "menuone", "noselect" }

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.showmode = false

vim.g.theme_flavor = "peach"
require("colors.colorscheme-flavor")
vim.cmd.colorscheme "catppuccin"

vim.filetype.add({ extension = { slur = "slur", }, })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(event)
    vim.keymap.set("n", "dd", function()
      local qf_list = vim.fn.getqflist()
      local cursor_idx = vim.api.nvim_win_get_cursor(0)[1]

      if #qf_list > 0 then
        table.remove(qf_list, cursor_idx)
        vim.fn.setqflist(qf_list, 'r')

        local new_idx = math.max(1, math.min(cursor_idx, #qf_list))
        if new_idx > 0 then
          vim.api.nvim_win_set_cursor(0, { new_idx, 0 })
        end
      end
    end, { buffer = event.buf, silent = true, desc = "Remover item da Quickfix" })
  end,
})

local last_diag_count = -1

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup("LspQuickfixSync", { clear = true }),
  callback = function()
    local qf = vim.fn.getqflist({ title = 1, size = 1 })

    if qf.size == 0 or qf.title == "Diagnostics" then
      local diags = vim.diagnostic.get(nil, { severity = { min = vim.diagnostic.severity.WARN } })
      local current_count = #diags

      if current_count > 0 then
        vim.diagnostic.setqflist({
          open = false,
          title = "Diagnostics",
          severity = { min = vim.diagnostic.severity.WARN },
        })
      else
        vim.fn.setqflist({}, 'r', { title = "Diagnostics" })
      end

      if current_count ~= last_diag_count then
        if current_count > 0 then
          vim.notify(current_count .. " erro(s)/aviso(s) listados.", vim.log.levels.WARN, { title = "LSP" })
        elseif last_diag_count > 0 and current_count == 0 then
          vim.notify("Erros corrigidos.", vim.log.levels.INFO, { title = "LSP" })
          vim.fn.setqflist({})
        end
        last_diag_count = current_count
      end
    end
  end,
})
