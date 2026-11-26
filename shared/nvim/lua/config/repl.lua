local terminal = require("config.terminal")

local M = {}

---@class ReplPaneSpec
---@field title string
---@field cmd string[]|fun(ctx: table): string[]
---@field ratio? number
---@field repl? boolean
---@field auto_close? boolean

---@class ReplSpec
---@field id string
---@field name? string
---@field width? number
---@field root? fun(buf: integer): string
---@field panes ReplPaneSpec[]
---@field get_block? fun(buf: integer, lnum: integer): integer, integer
---@field format_block? fun(lines: string[]): string
---@field reload_cmd? string|fun(ctx: table): string

---@type table<string, ReplSpec>
M.specs = {}

-- ---------------------------------------------------------------------------
-- Shared Block & Root Helpers (reusable for future specs like Common Lisp)
-- ---------------------------------------------------------------------------

local function has_cabal_file(dir)
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.cabal$") then
      return true
    end
  end
  return false
end

local function haskell_root(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local start_dir = (path ~= "" and vim.fs.dirname(path)) or vim.fn.getcwd()
  for dir in vim.fs.parents(start_dir .. "/_") do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, "stack.yaml"))
      or vim.uv.fs_stat(vim.fs.joinpath(dir, "cabal.project"))
      or vim.uv.fs_stat(vim.fs.joinpath(dir, "hie.yaml"))
      or has_cabal_file(dir)
    then
      return dir
    end
  end
  return vim.fs.root(buf, { ".git" }) or start_dir
end

local function haskell_kind(root)
  if vim.uv.fs_stat(vim.fs.joinpath(root, "stack.yaml")) then
    return "stack"
  end
  if vim.uv.fs_stat(vim.fs.joinpath(root, "cabal.project")) or has_cabal_file(root) then
    return "cabal"
  end
  return "file"
end

function M.paragraph_block(buf, lnum)
  local total = vim.api.nvim_buf_line_count(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, total, false)
  local s, e = lnum, lnum

  if (lines[lnum] or ""):match("^%s*$") then
    return lnum, lnum
  end
  while s > 1 and not (lines[s - 1] or ""):match("^%s*$") do
    s = s - 1
  end
  while e < total and not (lines[e + 1] or ""):match("^%s*$") do
    e = e + 1
  end
  return s, e
end

-- ---------------------------------------------------------------------------
-- Registry
-- ---------------------------------------------------------------------------

---@param filetypes string|string[]
---@param spec ReplSpec
function M.register(filetypes, spec)
  local list = type(filetypes) == "table" and filetypes or { filetypes }
  for _, ft in ipairs(list) do
    M.specs[ft] = spec
  end
end

M.register({ "haskell", "lhaskell" }, {
  id = "haskell",
  name = "haskell",
  width = 0.45,
  root = haskell_root,
  panes = {
    {
      title = "ghcid",
      ratio = 0.35,
      auto_close = false,
      cmd = function(ctx)
        local kind = haskell_kind(ctx.root)
        if kind == "stack" or kind == "cabal" then
          return { "ghcid", "--clear" }
        elseif ctx.file ~= "" then
          return { "ghcid", "--clear", ctx.file }
        end
        return { "ghcid", "--clear" }
      end,
    },
    {
      title = "ghci",
      ratio = 0.65,
      repl = true,
      auto_close = false,
      cmd = function(ctx)
        local kind = haskell_kind(ctx.root)
        if kind == "stack" then
          return { "stack", "ghci" }
        elseif kind == "cabal" then
          return { "cabal", "repl" }
        elseif ctx.file ~= "" then
          return { "ghci", ctx.file }
        end
        return { "ghci" }
      end,
    },
  },
  get_block = M.paragraph_block,
  format_block = function(lines)
    if #lines > 1 then
      return ":{\n" .. table.concat(lines, "\n") .. "\n:}\n"
    end
    return (lines[1] or "") .. "\n"
  end,
  reload_cmd = ":reload\n",
})

-- ---------------------------------------------------------------------------
-- Execution Helpers
-- ---------------------------------------------------------------------------

local function build_context(spec, buf)
  local root = spec.root and spec.root(buf) or (vim.fs.root(buf, { ".git" }) or vim.fn.getcwd())
  return {
    buf = buf,
    file = vim.api.nvim_buf_get_name(buf),
    root = root,
  }
end

local function resolve_panes(spec, ctx)
  local resolved = {}
  for _, p in ipairs(spec.panes) do
    local cmd = type(p.cmd) == "function" and p.cmd(ctx) or p.cmd
    table.insert(resolved, {
      title = p.title,
      cmd = cmd,
      ratio = p.ratio,
      repl = p.repl,
      auto_close = p.auto_close,
      cwd = ctx.root,
    })
  end
  return resolved
end

local function ensure_workspace(spec, buf, opts)
  opts = opts or {}
  local ctx = build_context(spec, buf)
  local existed = terminal.get_repl_pane(spec.id) ~= nil
  terminal.open_workspace({
    id = spec.id,
    name = spec.name or spec.id,
    cwd = ctx.root,
    width = spec.width or 0.45,
    panes = resolve_panes(spec, ctx),
    toggle = opts.toggle == true,
    focus = opts.focus,
  })
  return existed, ctx
end

local function send_payload(spec, buf, payload, start_lnum, end_lnum)
  if start_lnum and end_lnum then
    terminal.flash_lines(buf, start_lnum, end_lnum)
  end
  local existed = ensure_workspace(spec, buf, { toggle = false, focus = false })
  if existed then
    terminal.send(spec.id, payload)
  else
    vim.defer_fn(function()
      terminal.send(spec.id, payload)
    end, 600)
  end
end

local function format_lines(spec, lines)
  if spec.format_block then
    return spec.format_block(lines)
  end
  return table.concat(lines, "\n") .. "\n"
end

-- ---------------------------------------------------------------------------
-- Filetype-Scoped Keymaps
-- ---------------------------------------------------------------------------

local function attach(buf, spec)
  local function bmap(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end

  bmap("n", "<leader>tr", function()
    ensure_workspace(spec, buf, { toggle = true, focus = true })
  end, ("Toggle %s workspace"):format(spec.name or spec.id))

  bmap("n", "<leader>rs", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local getter = spec.get_block or M.paragraph_block
    local s, e = getter(buf, lnum)
    local lines = vim.api.nvim_buf_get_lines(buf, s - 1, e, false)
    send_payload(spec, buf, format_lines(spec, lines), s, e)
  end, "Send block to REPL")

  bmap("x", "<leader>rs", function()
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local s = math.min(start_pos[2], end_pos[2])
    local e = math.max(start_pos[2], end_pos[2])
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    local lines = vim.api.nvim_buf_get_lines(buf, s - 1, e, false)
    send_payload(spec, buf, format_lines(spec, lines), s, e)
  end, "Send selection to REPL")

  bmap("n", "<leader>rl", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)
    send_payload(spec, buf, format_lines(spec, lines), lnum, lnum)
  end, "Send line to REPL")

  if spec.reload_cmd then
    bmap("n", "<leader>rr", function()
      if vim.bo[buf].modified then
        vim.cmd.write()
      end
      local ctx = build_context(spec, buf)
      local cmd = type(spec.reload_cmd) == "function" and spec.reload_cmd(ctx) or spec.reload_cmd
      send_payload(spec, buf, cmd)
    end, "Save and reload REPL")
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("dotfiles.repl", { clear = true }),
    callback = function(ev)
      local spec = M.specs[ev.match]
      if spec then
        attach(ev.buf, spec)
      end
    end,
  })
end

return M
