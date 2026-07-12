return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    dependencies = { "echasnovski/mini.nvim" },
    opts = {
      latex = { enabled = false },
    },
  },
  {
    "toppair/peek.nvim",
    cmd = { "PeekOpen", "PeekClose" },
    build = "deno task --quiet build:fast",
    opts = { app = "browser" },
    config = function(_, opts)
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
}
