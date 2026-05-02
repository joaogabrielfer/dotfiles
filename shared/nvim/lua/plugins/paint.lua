return {
  "folke/paint.nvim",
  config = function()
    -- We will build the highlights list programmatically to keep it clean
    local slur_highlights = {}

    -- Helper function to safely add exact-word matches
    local function add_keywords(words, hl_group)
      for _, word in ipairs(words) do
        table.insert(slur_highlights, {
          filter = { filetype = "slur" },
          -- %f[%w] is Lua's word boundary. It prevents 'fun' from matching 'funny'
          pattern = "%f[%w]" .. word .. "%f[%W]",
          hl = hl_group,
        })
      end
    end

    -- 1. Keywords (Control flow and declarations)
    add_keywords({ "fun", "call", "if", "else", "var", "into", "quit" }, "Keyword")

    -- 2. Built-in Stack Operations
    add_keywords({ "push", "pop", "drop", "dup", "swap", "splitb", "len", "rot", "over" }, "Function")

    -- 3. Operators
    add_keywords({ "add", "sub", "mul", "div", "neg", "eq", "lt", "gt", "and", "or" }, "Operator")

    -- 4. Booleans
    add_keywords({ "true", "false" }, "Boolean")

    -- 5. Numbers (Matches optional negative sign followed by digits)
    table.insert(slur_highlights, {
      filter = { filetype = "slur" },
      pattern = "%-?%d+",
      hl = "Number",
    })

    -- 6. Strings (Uses Lua's non-greedy match '.-' inside quotes)
    table.insert(slur_highlights, {
      filter = { filetype = "slur" },
      pattern = '".-"',
      hl = "String",
    })

    -- 7. Comments (From ;; to the end of the line)
    table.insert(slur_highlights, {
      filter = { filetype = "slur" },
      pattern = ";;.*",
      hl = "Comment",
    })

    -- Finally, pass our built table to paint!
    require("paint").setup({
      highlights = slur_highlights,
    })
  end,
}
