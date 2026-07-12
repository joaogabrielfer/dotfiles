return {
  "nvim-treesitter/nvim-treesitter",
  commit = "cf12346a3414fa1b06af75c79faebe7f76df080a",
  build = ":TSUpdate",
  config = function()
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

    -- nvim-treesitter master still registers some directives with the old
    -- capture shape. Neovim 0.12 passes captures as TSNode[] lists, which
    -- otherwise makes markdown injections pass a table to get_node_text().
    local query = require("vim.treesitter.query")
    local function first_capture(match, capture_id)
      local capture = match[capture_id]
      if type(capture) == "table" then
        return capture[1]
      end
      return capture
    end

    local markdown_aliases = {
      ex = "elixir",
      pl = "perl",
      sh = "bash",
      uxn = "uxntal",
      ts = "typescript",
    }

    local function parser_from_info_string(alias)
      return vim.filetype.match({ filename = "a." .. alias }) or markdown_aliases[alias] or alias
    end

    query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
      local node = first_capture(match, pred[2])
      if not node then
        return
      end

      local alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata["injection.language"] = parser_from_info_string(alias)
    end, { force = true })

    query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
      local capture_id = pred[2]
      local node = first_capture(match, capture_id)
      if not node then
        return
      end

      local capture_metadata = metadata[capture_id] or {}
      metadata[capture_id] = capture_metadata
      local text = vim.treesitter.get_node_text(node, bufnr, { metadata = capture_metadata }) or ""
      capture_metadata.text = string.lower(text)
    end, { force = true })

    -- tree-sitter CLI >= 0.24 dropped --no-bindings; override the args that
    -- nvim-treesitter (master) still hard-codes with the removed flag.
    local install = require("nvim-treesitter.install")
    install.ts_generate_args = { "generate", "--abi", tostring(vim.treesitter.language_version) }

    -- Register the custom pasm parser.
    parser_config.pasm = {
      install_info = {
        url = "~/personal/programming/projects/pyx-pasm/tree-sitter-pasm",
        files = { "src/parser.c" },
        generate_requires_npm = true,
        requires_generate_from_grammar = true,
      },
      filetype = "pasm",
    }

    -- Make the parser's queries/ dir (highlights.scm, etc.) visible to Neovim.
    -- nvim-treesitter only ships queries for its own built-in parsers.
    vim.opt.runtimepath:append(vim.fn.expand("~/personal/programming/projects/pyx-pasm/tree-sitter-pasm"))

    -- Map the .pasm extension to the "pasm" filetype.
    vim.filetype.add({
      extension = {
        pasm = "pasm",
      },
    })

    -- Languages that should always be present.
    local ensure_installed = {
      "bash", "c", "html", "javascript", "json",
      "lua", "markdown", "markdown_inline", "python",
      "query", "regex", "rust", "toml", "tsx", "typescript",
      "vim", "vimdoc", "yaml", "pasm", "gleam",
    }

    -- Only install parsers that are not already available.
    local installed = require("nvim-treesitter.info").installed_parsers()
    local to_install = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, ensure_installed)

    if #to_install > 0 then
      require("nvim-treesitter.install").ensure_installed(unpack(to_install))
    end

    -- Collect all filetypes handled by the installed parsers.
    -- Use the lang name itself as a fallback when get_filetypes() returns
    -- nothing (e.g. for custom parsers not registered with the runtime).
    local filetypes = {}
    local seen = {}
    for _, lang in ipairs(ensure_installed) do
      local fts = vim.treesitter.language.get_filetypes(lang)
      if #fts == 0 then fts = { lang } end
      for _, ft in ipairs(fts) do
        if not seen[ft] then
          seen[ft] = true
          table.insert(filetypes, ft)
        end
      end
    end

    -- Enable native treesitter highlighting for every matched filetype.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("StartTreesitter", { clear = true }),
      pattern = filetypes,
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })
  end,
}
