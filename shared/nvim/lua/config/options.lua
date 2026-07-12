vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt
local undo_dir = vim.fn.stdpath("state") .. "/undo"

opt.backup = false
opt.clipboard = "unnamedplus"
opt.completeopt = { "menuone", "noselect", "popup" }
opt.confirm = true
opt.hlsearch = false
opt.ignorecase = true
opt.incsearch = true
opt.number = true
opt.relativenumber = true
opt.scrolloff = 8
opt.shiftwidth = 4
opt.showmode = false
opt.signcolumn = "yes"
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.tabstop = 4
opt.undodir = undo_dir
opt.undofile = true
opt.updatetime = 200
opt.winborder = "rounded"

vim.fn.mkdir(undo_dir, "p")

vim.filetype.add({
  extension = {
    pasm = "pasm",
    slur = "slur",
  },
})

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
