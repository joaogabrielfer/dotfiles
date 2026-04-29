return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    -- A sua lista de linguagens
    local ensure_installed = {
      "bash", "c", "html", "javascript", "json",
      "lua", "markdown", "markdown_inline", "python", 
      "query", "regex", "rust", "toml", "tsx", "typescript", 
      "vim", "vimdoc", "yaml"
    }

    -- 1. Instala apenas o que estiver faltando
    local to_install = vim.tbl_filter(function(lang)
      return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
    end, ensure_installed)

    if #to_install > 0 then
      ts.install(to_install)
    end

    -- 2. Descobre os filetypes
    local filetypes = {}
    for _, lang in ipairs(ensure_installed) do
      for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
        table.insert(filetypes, ft)
      end
    end

    -- 3. Ativa a coloração do Treesitter nativamente
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("StartTreesitter", { clear = true }),
      pattern = filetypes,
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })
  end,
}
