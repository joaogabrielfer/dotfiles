local map = vim.keymap.set

local ROOT_MARKERS = {
  ".git",
  "Cargo.toml",
  "go.mod",
  "package.json",
  "stack.yaml",
  "cabal.project",
  function(name)
    return name:match("%.cabal$") ~= nil
  end,
}

local function project_root()
  local root = vim.fs.root(0, ROOT_MARKERS)
  if root then
    local norm = vim.fs.normalize(root)
    local home = vim.fs.normalize(vim.uv.os_homedir() or "")
    if norm ~= home and norm ~= "/" then
      return root
    end
  end
  return vim.fn.getcwd()
end

local function project_picker(name)
  return function()
    Snacks.picker[name]({ cwd = project_root() })
  end
end

-- Snacks
require("snacks").setup({
  input = { enabled = true },
  picker = {
    enabled = true,
    formatters = {
      file = {
        filename_first = false,
        filename_only = false,
      },
    },
  },
  scratch = { enabled = true },
})

map("n", "<leader><space>s", project_picker("smart"), { desc = "Smart files" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>ff", function() Snacks.picker.files({ cwd = true }) end, { desc = "Files" })
map("n", "<leader>FF", project_picker("files"), { desc = "Project files" })
map("n", "<leader>fg", project_picker("git_files"), { desc = "Git files" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })
map("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep" })
map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
map("n", "<leader>sj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix" })
map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, { desc = "Document symbols" })
map("n", "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "Workspace symbols" })
map("n", "<leader>su", function() Snacks.picker.undo() end, { desc = "Undo history" })
map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Scratch buffer" })
map("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select scratch buffer" })

-- Mini
require("mini.icons").setup()
require("mini.statusline").setup({ use_icons = true })
require("mini.pairs").setup({
  modes = { insert = true, command = false, terminal = false },
  markdown = false,
})
MiniPairs.unmap("i", '"', '"')
MiniPairs.unmap("i", "'", "'")
require("mini.indentscope").setup({
  draw = { animation = require("mini.indentscope").gen_animation.none() },
})
require("mini.surround").setup()
require("mini.align").setup()
require("mini.ai").setup()
require("mini.trailspace").setup()
require("mini.move").setup()

-- Oil
require("oil").setup({
  view_options = { show_hidden = true },
  use_default_keymaps = false,
  keymaps = {
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["gt"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = "actions.close",
    ["<C-r>"] = "actions.refresh",
    ["-"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = { "actions.cd", opts = { scope = "tab" } },
    ["gs"] = "actions.change_sort",
    ["gx"] = "actions.open_external",
    ["g."] = "actions.toggle_hidden",
    ["g\\"] = "actions.toggle_trash",
  },
})

map("n", "-", "<cmd>Oil<cr>", { desc = "Oil parent directory" })
map("n", "_", "<cmd>Oil .<cr>", { desc = "Oil working directory" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.oil-snacks-main", { clear = true }),
  pattern = "oil",
  callback = function(ev)
    vim.b[ev.buf].snacks_main = true
  end,
})

-- WhichKey (deferred to UIEnter)
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("dotfiles.whichkey", { clear = true }),
  once = true,
  callback = function()
    require("which-key").setup({
      delay = 250,
      preset = "modern",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>r", group = "repl" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "terminal" },
        { "<leader>u", group = "toggle" },
        { "<leader>x", group = "execute" },
        { "<leader>y", group = "yank" },
      },
    })
  end,
})

map("n", "<leader>?", function()
  require("which-key").show({ keys = "<leader>", loop = true })
end, { desc = "Leader keymaps" })
