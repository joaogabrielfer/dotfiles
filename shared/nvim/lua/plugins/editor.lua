local function project_root()
  return vim.fs.root(0, { ".git", "Cargo.toml", "go.mod", "package.json" }) or vim.fn.getcwd()
end

local function project_picker(name)
  return function()
    Snacks.picker[name]({ cwd = project_root() })
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
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
    },
    keys = {
      { "<leader><space>s", project_picker("smart"), desc = "Smart files" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>ff", function() Snacks.picker.files({cwd = true}) end, desc = "Files" },
      { "<leader>FF", project_picker("files"), desc = "Files" },
      { "<leader>fg", project_picker("git_files"), desc = "Git files" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
      { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Scratch buffer" },
      { "<leader>S", function() Snacks.scratch.select() end, desc = "Select scratch buffer" },
    },
  },
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.icons").setup()
      require("mini.statusline").setup({ use_icons = true })
      require("mini.pairs").setup({
        modes = { insert = true, command = false, terminal = false },
        markdown = false,
      })
      MiniPairs.unmap("i", '"', '"')
      MiniPairs.unmap("i", '\'', '\'')
      require("mini.indentscope").setup({
        draw = { animation = require("mini.indentscope").gen_animation.none() },
      })
      require("mini.surround").setup()
      require("mini.align").setup()
      require("mini.ai").setup()
      require("mini.trailspace").setup()
      require("mini.move").setup()
    end,
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "echasnovski/mini.nvim" },
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Oil parent directory" },
      { "_", "<cmd>Oil .<cr>", desc = "Oil working directory" },
    },
    opts = {
      view_options = { show_hidden = true },
      use_default_keymaps = false,
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = { "actions.select", opts = { vertical = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
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
    },
  },
  {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      {
        "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add"
      },
      {
        "<leader>hh",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon menu",
      },
      { "<C-h>", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
      { "<C-j>", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
      { "<C-k>", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
      { "<C-l>", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 250,
      preset = "modern",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "harpoon" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "toggle" },
        { "<leader>x", group = "execute" },
        { "<leader>y", group = "yank" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ keys = "<leader>", loop = true })
        end,
        desc = "Leader keymaps",
      },
    },
  },
}
