return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      signcolumn = false,
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        local function buffer_map(mode, lhs, rhs, desc, options)
          vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
            buffer = bufnr,
            desc = desc,
          }, options or {}))
        end

        buffer_map("n", "]h", function()
          if vim.wo.diff then
            return "]h"
          end
          vim.schedule(gitsigns.next_hunk)
          return "<Ignore>"
        end, "Next Git hunk", { expr = true })
        buffer_map("n", "[h", function()
          if vim.wo.diff then
            return "[h"
          end
          vim.schedule(gitsigns.prev_hunk)
          return "<Ignore>"
        end, "Previous Git hunk", { expr = true })
        buffer_map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage Git hunk")
        buffer_map("n", "<leader>ghr", gitsigns.reset_hunk, "Reset Git hunk")
        buffer_map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview Git hunk")
        buffer_map("n", "<leader>gb", gitsigns.toggle_current_line_blame, "Toggle Git blame")
      end,
    },
  },
}
