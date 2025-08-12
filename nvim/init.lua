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

vim.opt.completeopt = { "menuone", "noselect" }

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

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
