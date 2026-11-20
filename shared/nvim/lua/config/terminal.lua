local M = {}

local link_ns = vim.api.nvim_create_namespace("dotfiles.term.links")
local hint_ns = vim.api.nvim_create_namespace("dotfiles.term.hints")
local eval_ns = vim.api.nvim_create_namespace("dotfiles.term.eval")
local augroup = vim.api.nvim_create_augroup("dotfiles.terminal", { clear = true })

local DEFAULT_WIDTH = 0.42
local MIN_WIDTH = 30
local FLOAT_ID = "float"

---@class TermPane
---@field buf integer
---@field win integer?
---@field job_id integer?
---@field title string
---@field ratio number
---@field repl boolean
---@field cwd string
---@field auto_close boolean
---@field exited boolean
---@field exit_code integer?

---@class TermGroup
---@field id string
---@field name string
---@field is_float boolean
---@field width number
---@field cwd string
---@field panes TermPane[]
---@field last_pane_idx integer

---@type table<string, TermGroup>
local groups = {}
---@type string[]
local group_order = {}
---@type string?
local active_group_id = nil
---@type string
local last_group_id = "1"
---@type integer?
local last_editor_win = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function is_valid_buf(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function is_term_buf(buf)
  return is_valid_buf(buf) and vim.bo[buf].buftype == "terminal"
end

local function is_editor_win(win)
  if not is_valid_win(win) then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local bt = vim.bo[buf].buftype
  return bt == "" or bt == "acwrite"
end

local function default_shell()
  if vim.o.shell and vim.o.shell ~= "" then
    return { vim.o.shell }
  end
  return { "fish" }
end

local function shell_title(cmd)
  if type(cmd) == "table" and cmd[1] then
    return vim.fn.fnamemodify(cmd[1], ":t")
  elseif type(cmd) == "string" and cmd ~= "" then
    return vim.fn.fnamemodify(vim.split(cmd, "%s+")[1], ":t")
  end
  return vim.fn.fnamemodify(vim.o.shell, ":t")
end

local function escape_stl(str)
  return (tostring(str):gsub("%%", "%%%%"))
end

local function short_path(dir)
  return vim.fn.fnamemodify(dir, ":~")
end

local function project_root_or_cwd()
  local root = vim.fs.root(0, { ".git", "Cargo.toml", "go.mod", "package.json", "*.cabal", "stack.yaml", "cabal.project" })
  return root or vim.fn.getcwd()
end

local function find_by_buf(buf)
  for _, group in pairs(groups) do
    for idx, pane in ipairs(group.panes) do
      if pane.buf == buf then
        return group, pane, idx
      end
    end
  end
  return nil, nil, nil
end

local function is_group_visible(group)
  if not group then
    return false
  end
  for _, pane in ipairs(group.panes) do
    if is_valid_win(pane.win) and vim.api.nvim_win_get_buf(pane.win) == pane.buf then
      return true
    end
  end
  return false
end

local function remove_from_order(id)
  for i, gid in ipairs(group_order) do
    if gid == id then
      table.remove(group_order, i)
      return
    end
  end
end

local function prune_group(group)
  local kept = {}
  for _, pane in ipairs(group.panes) do
    if is_valid_buf(pane.buf) then
      if not is_valid_win(pane.win) then
        pane.win = nil
      end
      table.insert(kept, pane)
    end
  end
  group.panes = kept
  if #group.panes == 0 then
    groups[group.id] = nil
    remove_from_order(group.id)
    if active_group_id == group.id then
      active_group_id = nil
    end
    if last_group_id == group.id then
      last_group_id = group_order[1] or "1"
    end
    return false
  end
  group.last_pane_idx = math.min(math.max(group.last_pane_idx or 1, 1), #group.panes)
  return true
end

local function find_editor_win()
  if is_editor_win(last_editor_win) then
    return last_editor_win
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(win) then
      return win
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Highlights & Winbar
-- ---------------------------------------------------------------------------

local function setup_highlights()
  local ok, theme = pcall(require, "config.theme")
  local palette = ok and theme.palette or nil
  if palette and palette.colors then
    local c = palette.colors
    local accent = c[palette.accent] or c.peach or c.blue
    vim.api.nvim_set_hl(0, "TermBarActive", { fg = c.crust, bg = accent, bold = true })
    vim.api.nvim_set_hl(0, "TermBarTitle", { fg = accent, bg = c.crust, bold = true })
    vim.api.nvim_set_hl(0, "TermBarInactive", { fg = c.overlay1, bg = c.crust })
    vim.api.nvim_set_hl(0, "TermBarFill", { fg = c.subtext0, bg = c.crust })
    vim.api.nvim_set_hl(0, "TermLink", { fg = c.sky or accent, underline = true })
    vim.api.nvim_set_hl(0, "TermHint", { fg = c.crust, bg = accent, bold = true })
    vim.api.nvim_set_hl(0, "TermEvalFlash", { bg = c.surface1 })
  else
    vim.api.nvim_set_hl(0, "TermBarActive", { link = "Visual" })
    vim.api.nvim_set_hl(0, "TermBarTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "TermBarInactive", { link = "Comment" })
    vim.api.nvim_set_hl(0, "TermBarFill", { link = "StatusLine" })
    vim.api.nvim_set_hl(0, "TermLink", { underline = true })
    vim.api.nvim_set_hl(0, "TermHint", { link = "IncSearch" })
    vim.api.nvim_set_hl(0, "TermEvalFlash", { link = "Visual" })
  end
end

local function build_group_pills(current_id)
  local parts = {}
  for _, gid in ipairs(group_order) do
    local g = groups[gid]
    if g and not g.is_float and #g.panes > 0 then
      local label = escape_stl(g.name)
      if gid == current_id then
        table.insert(parts, "%#TermBarActive# ● " .. label .. " %#TermBarFill#")
      else
        table.insert(parts, "%#TermBarInactive# " .. label .. " %#TermBarFill#")
      end
    end
  end
  return table.concat(parts, " ")
end

local function refresh_winbars()
  local cur_win = vim.api.nvim_get_current_win()
  for _, group in pairs(groups) do
    if not group.is_float then
      local pills = build_group_pills(group.id)
      local total = #group.panes
      for idx, pane in ipairs(group.panes) do
        if is_valid_win(pane.win) and vim.api.nvim_win_get_buf(pane.win) == pane.buf then
          local is_focused = pane.win == cur_win
          local title_hl = is_focused and "%#TermBarTitle#" or "%#TermBarInactive#"
          local status = pane.exited and (" [exit " .. tostring(pane.exit_code or 0) .. "]") or ""
          local left = string.format(
            "%s [%s] %s (%d/%d)%s %%#TermBarFill#",
            title_hl,
            escape_stl(group.name),
            escape_stl(pane.title),
            idx,
            total,
            escape_stl(status)
          )
          vim.wo[pane.win].winbar = left .. "%=" .. pills .. " "
        end
      end
    else
      local pane = group.panes[1]
      if pane and is_valid_win(pane.win) then
        local title = string.format(" [%s] %s ", group.name, short_path(pane.cwd))
        pcall(vim.api.nvim_win_set_config, pane.win, { title = title, title_pos = "center" })
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Link & File-Location Parsing, Underlining, <S-CR>, gl (Ace-Link), gq (Quickfix)
-- ---------------------------------------------------------------------------

local function resolve_existing_file(raw_path, cwd_candidates)
  if not raw_path or raw_path == "" then
    return nil
  end
  local expanded = raw_path
  if vim.startswith(expanded, "~/") then
    expanded = vim.fn.expand(expanded)
  end
  if vim.startswith(expanded, "/") then
    local stat = vim.uv.fs_stat(expanded)
    if stat and stat.type == "file" then
      return expanded
    end
    return nil
  end
  for _, base in ipairs(cwd_candidates) do
    if base and base ~= "" then
      local candidate = vim.fs.normalize(vim.fs.joinpath(base, expanded))
      local stat = vim.uv.fs_stat(candidate)
      if stat and stat.type == "file" then
        return candidate
      end
    end
  end
  return nil
end

local function trim_url(url)
  while true do
    local last = url:sub(-1)
    if last == "." or last == "," or last == ";" or last == ":" or last == "!" or last == "?" or last == "'" or last == '"' then
      url = url:sub(1, -2)
    elseif last == ")" then
      local _, opens = url:gsub("%(", "")
      local _, closes = url:gsub("%)", "")
      if closes > opens then
        url = url:sub(1, -2)
      else
        break
      end
    elseif last == "]" then
      local _, opens = url:gsub("%[", "")
      local _, closes = url:gsub("%]", "")
      if closes > opens then
        url = url:sub(1, -2)
      else
        break
      end
    else
      break
    end
  end
  return url
end

local function overlaps(spans, s, e)
  for _, sp in ipairs(spans) do
    if not (e <= sp.col_start or s >= sp.col_end) then
      return true
    end
  end
  return false
end

---@return table[]
local function extract_line_targets(line, lnum, cwd_candidates)
  local targets = {}

  -- 1. URLs
  local pos = 1
  while true do
    local s, e = line:find("https?://[^%s<>\"'`]+", pos)
    if not s then
      break
    end
    local cleaned = trim_url(line:sub(s, e))
    local end_col = s - 1 + #cleaned
    if #cleaned > 8 then
      table.insert(targets, {
        kind = "url",
        url = cleaned,
        lnum = lnum,
        col_start = s - 1,
        col_end = end_col,
        text = line,
      })
    end
    pos = e + 1
  end

  -- 2. GHC range locations: path/File.hs:(42,10)-(44,5)
  pos = 1
  while true do
    local s, e, raw_path, ln, col = line:find("([%w%._/%-~]+%.l?hs):%((%d+),(%d+)%)", pos)
    if not s then
      break
    end
    local full_e = e
    local _, range_end = line:find("^%-%(%d+,%d+%)", e + 1)
    if range_end then
      full_e = range_end
    end
    if not overlaps(targets, s - 1, full_e) then
      local resolved = resolve_existing_file(raw_path, cwd_candidates)
      if resolved then
        table.insert(targets, {
          kind = "file",
          path = resolved,
          target_lnum = tonumber(ln) or 1,
          target_col = tonumber(col) or 1,
          lnum = lnum,
          col_start = s - 1,
          col_end = full_e,
          text = line,
        })
      end
    end
    pos = full_e + 1
  end

  -- 3. Python tracebacks: File "/path/file.py", line 42
  pos = 1
  while true do
    local s, e, raw_path, ln = line:find('File "([^"]+)", line (%d+)', pos)
    if not s then
      break
    end
    if not overlaps(targets, s - 1, e) then
      local resolved = resolve_existing_file(raw_path, cwd_candidates)
      if resolved then
        table.insert(targets, {
          kind = "file",
          path = resolved,
          target_lnum = tonumber(ln) or 1,
          target_col = 1,
          lnum = lnum,
          col_start = s - 1,
          col_end = e,
          text = line,
        })
      end
    end
    pos = e + 1
  end

  -- 4. Generic file:line(:col)? (Rust, Go, C, TS, GHC single-point, etc.)
  pos = 1
  while true do
    local s, e, raw_path, ln, col = line:find("([%w%._/%-~]+):(%d+):?(%d*)", pos)
    if not s then
      break
    end
    if not overlaps(targets, s - 1, e) then
      local resolved = resolve_existing_file(raw_path, cwd_candidates)
      if resolved then
        table.insert(targets, {
          kind = "file",
          path = resolved,
          target_lnum = tonumber(ln) or 1,
          target_col = (col and col ~= "") and tonumber(col) or 1,
          lnum = lnum,
          col_start = s - 1,
          col_end = e,
          text = line,
        })
      end
    end
    pos = e + 1
  end

  table.sort(targets, function(a, b)
    return a.col_start < b.col_start
  end)
  return targets
end

local function cwd_candidates_for_buf(buf)
  local group, pane = find_by_buf(buf)
  local list = {}
  if pane and pane.cwd then
    table.insert(list, pane.cwd)
  end
  if group and group.cwd and group.cwd ~= (pane and pane.cwd) then
    table.insert(list, group.cwd)
  end
  table.insert(list, vim.fn.getcwd())
  return list
end

local function collect_targets(buf, first_lnum, last_lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, first_lnum - 1, last_lnum, false)
  local cwds = cwd_candidates_for_buf(buf)
  local all = {}
  for i, line in ipairs(lines) do
    local line_targets = extract_line_targets(line, first_lnum + i - 1, cwds)
    for _, t in ipairs(line_targets) do
      table.insert(all, t)
    end
  end
  return all
end

local function clear_link_highlights(buf)
  if is_valid_buf(buf) then
    vim.api.nvim_buf_clear_namespace(buf, link_ns, 0, -1)
  end
end

local function update_link_highlights(win)
  win = win or vim.api.nvim_get_current_win()
  if not is_valid_win(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if not is_term_buf(buf) then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if win == vim.api.nvim_get_current_win() and mode:sub(1, 1) == "t" then
    clear_link_highlights(buf)
    return
  end

  clear_link_highlights(buf)
  local top = vim.fn.line("w0", win)
  local bot = vim.fn.line("w$", win)
  if top <= 0 or bot < top then
    return
  end

  local targets = collect_targets(buf, top, bot)
  for _, t in ipairs(targets) do
    pcall(vim.api.nvim_buf_set_extmark, buf, link_ns, t.lnum - 1, t.col_start, {
      end_row = t.lnum - 1,
      end_col = t.col_end,
      hl_group = "TermLink",
      priority = 110,
    })
  end
end

---@param path string
---@param lnum? integer
---@param col? integer
function M.open_in_editor(path, lnum, col)
  if not path or path == "" then
    return
  end
  local float_group = groups[FLOAT_ID]
  if float_group and is_group_visible(float_group) then
    M.hide(FLOAT_ID)
  end

  local target_win = find_editor_win()
  if not target_win then
    vim.cmd("topleft vertical split")
    target_win = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_set_current_win(target_win)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  if lnum and lnum > 0 then
    local line_count = vim.api.nvim_buf_line_count(0)
    local row = math.min(lnum, math.max(line_count, 1))
    local col0 = math.max((col or 1) - 1, 0)
    pcall(vim.api.nvim_win_set_cursor, target_win, { row, col0 })
    vim.cmd("normal! zz")
  end
  last_editor_win = target_win
end

local function activate_target(target)
  if target.kind == "url" then
    vim.ui.open(target.url)
  elseif target.kind == "file" then
    M.open_in_editor(target.path, target.target_lnum, target.target_col)
  end
end

local function target_at_position(buf, lnum, col0)
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
  if not line then
    return nil
  end
  local cwds = cwd_candidates_for_buf(buf)
  local targets = extract_line_targets(line, lnum, cwds)

  for _, t in ipairs(targets) do
    if col0 >= t.col_start and col0 < t.col_end then
      return t
    end
  end
  if targets[1] then
    return targets[1]
  end

  -- Fallback: bare file path under cursor (<cfile>)
  local cfile = vim.fn.expand("<cfile>")
  local resolved = resolve_existing_file(cfile, cwds)
  if resolved then
    return { kind = "file", path = resolved, target_lnum = 1, target_col = 1 }
  end
  return nil
end

function M.jump_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local target = target_at_position(buf, pos[1], pos[2])
  if not target then
    vim.notify("No link or file location on this line", vim.log.levels.INFO)
    return
  end
  activate_target(target)
end

function M.jump_at_mouse()
  local m = vim.fn.getmousepos()
  if not is_valid_win(m.winid) or m.line <= 0 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(m.winid)
  if not is_term_buf(buf) then
    return
  end
  local target = target_at_position(buf, m.line, math.max(m.column - 1, 0))
  if target then
    activate_target(target)
  end
end

local HINT_KEYS = { "a", "s", "d", "f", "g", "h", "j", "k", "l", "w", "e", "r", "u", "i", "o", "p", "c", "v", "n", "m" }

local function generate_labels(count)
  if count <= #HINT_KEYS then
    return vim.list_slice(HINT_KEYS, 1, count)
  end
  local labels = {}
  for _, first in ipairs(HINT_KEYS) do
    for _, second in ipairs(HINT_KEYS) do
      table.insert(labels, first .. second)
      if #labels >= count then
        return labels
      end
    end
  end
  return labels
end

function M.hint_jump()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  if not is_term_buf(buf) then
    return
  end

  local top = vim.fn.line("w0", win)
  local bot = vim.fn.line("w$", win)
  local targets = collect_targets(buf, top, bot)
  if #targets == 0 then
    vim.notify("No visible links or file locations", vim.log.levels.INFO)
    return
  end
  if #targets == 1 then
    activate_target(targets[1])
    return
  end

  local labels = generate_labels(#targets)
  local label_map = {}
  local is_two_char = #labels[1] == 2

  local function render_hints(prefix)
    vim.api.nvim_buf_clear_namespace(buf, hint_ns, 0, -1)
    for i, target in ipairs(targets) do
      local label = labels[i]
      if not prefix or vim.startswith(label, prefix) then
        label_map[label] = target
        vim.api.nvim_buf_set_extmark(buf, hint_ns, target.lnum - 1, target.col_start, {
          virt_text = { { " " .. label .. " ", "TermHint" } },
          virt_text_pos = "overlay",
          priority = 200,
        })
      end
    end
    vim.cmd.redraw()
  end

  render_hints(nil)

  local ok1, c1 = pcall(vim.fn.getcharstr)
  local chosen = nil
  if ok1 and c1 and c1 ~= "" and c1 ~= "\27" and c1 ~= "\3" then
    if not is_two_char then
      chosen = label_map[c1]
    else
      render_hints(c1)
      local ok2, c2 = pcall(vim.fn.getcharstr)
      if ok2 and c2 and c2 ~= "" and c2 ~= "\27" and c2 ~= "\3" then
        chosen = label_map[c1 .. c2]
      end
    end
  end

  vim.api.nvim_buf_clear_namespace(buf, hint_ns, 0, -1)
  vim.cmd.redraw()

  if chosen then
    activate_target(chosen)
  end
end

function M.send_to_quickfix()
  local buf = vim.api.nvim_get_current_buf()
  if not is_term_buf(buf) then
    return
  end

  local _, pane = find_by_buf(buf)
  local total = vim.api.nvim_buf_line_count(buf)
  local start_lnum = math.max(1, total - 250)
  local end_lnum = total

  local output_start = vim.b[buf].term_last_output_start
  local prompts = vim.b[buf].term_prompts
  if type(output_start) == "number" and output_start >= 1 and output_start <= total then
    start_lnum = output_start
    if type(prompts) == "table" and #prompts > 0 and prompts[#prompts] > output_start then
      end_lnum = prompts[#prompts] - 1
    end
  elseif type(prompts) == "table" and #prompts >= 2 then
    start_lnum = prompts[#prompts - 1]
    end_lnum = math.max(start_lnum, prompts[#prompts] - 1)
  end

  local targets = collect_targets(buf, start_lnum, end_lnum)
  local seen = {}
  local items = {}
  for _, t in ipairs(targets) do
    if t.kind == "file" then
      local key = string.format("%s:%d:%d", t.path, t.target_lnum, t.target_col)
      if not seen[key] then
        seen[key] = true
        table.insert(items, {
          filename = t.path,
          lnum = t.target_lnum,
          col = t.target_col,
          text = vim.trim(t.text),
        })
      end
    end
  end

  if #items == 0 then
    vim.notify("No file locations found in recent terminal output", vim.log.levels.INFO)
    return
  end

  local title = "Terminal: " .. (pane and pane.title or "shell")
  vim.fn.setqflist({}, "r", { title = title, items = items })
  vim.notify(("%d locations sent to quickfix"):format(#items), vim.log.levels.INFO)
  vim.cmd("botright copen")
end

-- ---------------------------------------------------------------------------
-- Terminal Buffer & Window Management
-- ---------------------------------------------------------------------------

local function configure_term_win(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].scrolloff = 0
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].cursorline = false
  vim.wo[win].winfixwidth = true
end

local function configure_term_keymaps(buf)
  local opts = function(desc)
    return { buffer = buf, silent = true, desc = desc }
  end

  vim.keymap.set("n", "q", function()
    local group = find_by_buf(buf)
    if group then
      M.hide(group.id)
    elseif is_valid_win(vim.api.nvim_get_current_win()) then
      pcall(vim.api.nvim_win_close, 0, true)
    end
  end, opts("Hide terminal group"))

  vim.keymap.set("n", "Q", function()
    M.close_pane(buf)
  end, opts("Close terminal pane"))

  vim.keymap.set("n", "<CR>", "i", opts("Enter terminal mode"))
  vim.keymap.set("n", "<S-CR>", M.jump_at_cursor, opts("Jump to file or open URL"))
  vim.keymap.set({ "n", "t" }, "<S-LeftMouse>", M.jump_at_mouse, opts("Click file location or URL"))
  vim.keymap.set("n", "gl", M.hint_jump, opts("Hint-jump to link or location"))
  vim.keymap.set("n", "gq", M.send_to_quickfix, opts("Send terminal locations to quickfix"))
end

local function start_pane_in_current_win(pane, cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  configure_term_win(win)

  local job_id = vim.fn.jobstart(cmd, {
    term = true,
    cwd = pane.cwd,
  })

  pane.buf = buf
  pane.win = win
  pane.job_id = job_id
  pane.exited = false
  pane.exit_code = nil

  configure_term_keymaps(buf)
  return pane
end

local function snapshot_layout(group)
  if not group or group.is_float then
    return
  end
  local heights = {}
  local total_h = 0
  local width_cols = nil
  local cur_win = vim.api.nvim_get_current_win()

  for idx, pane in ipairs(group.panes) do
    if is_valid_win(pane.win) and vim.api.nvim_win_get_buf(pane.win) == pane.buf then
      local h = vim.api.nvim_win_get_height(pane.win)
      heights[idx] = h
      total_h = total_h + h
      if not width_cols then
        width_cols = vim.api.nvim_win_get_width(pane.win)
      end
      if pane.win == cur_win then
        group.last_pane_idx = idx
      end
    end
  end

  if width_cols and vim.o.columns > 0 then
    group.width = math.max(0.15, math.min(0.85, width_cols / vim.o.columns))
  end
  if total_h > 0 then
    for idx, h in pairs(heights) do
      group.panes[idx].ratio = h / total_h
    end
  end
end

local function apply_pane_ratios(group)
  if group.is_float or #group.panes <= 1 then
    return
  end
  local total_h = 0
  local total_ratio = 0
  for _, pane in ipairs(group.panes) do
    if is_valid_win(pane.win) then
      total_h = total_h + vim.api.nvim_win_get_height(pane.win)
      total_ratio = total_ratio + (pane.ratio or 1)
    end
  end
  if total_h <= 0 or total_ratio <= 0 then
    return
  end
  for i = 1, #group.panes - 1 do
    local pane = group.panes[i]
    if is_valid_win(pane.win) then
      local target_h = math.max(3, math.floor(total_h * ((pane.ratio or 1) / total_ratio) + 0.5))
      pcall(vim.api.nvim_win_set_height, pane.win, target_h)
    end
  end
end

function M.hide(id)
  local group = groups[id]
  if not group then
    return
  end
  snapshot_layout(group)
  for _, pane in ipairs(group.panes) do
    if is_valid_win(pane.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      pcall(vim.api.nvim_win_close, pane.win, true)
    end
    pane.win = nil
  end
  if active_group_id == id then
    active_group_id = nil
  end
  local editor_win = find_editor_win()
  if editor_win then
    pcall(vim.api.nvim_set_current_win, editor_win)
  end
end

local function ensure_group(id, opts)
  opts = opts or {}
  local group = groups[id]
  if group then
    prune_group(group)
    group = groups[id]
  end
  if not group then
    local cwd = opts.cwd or project_root_or_cwd()
    group = {
      id = id,
      name = opts.name or id,
      is_float = opts.is_float == true,
      width = opts.width or DEFAULT_WIDTH,
      cwd = cwd,
      panes = {},
      last_pane_idx = 1,
    }
    groups[id] = group
    if not group.is_float then
      table.insert(group_order, id)
    end
  end
  return group
end

local function open_group_windows(group, pane_specs, focus)
  if is_editor_win(vim.api.nvim_get_current_win()) then
    last_editor_win = vim.api.nvim_get_current_win()
  end

  if group.is_float then
    local width = math.max(40, math.floor(vim.o.columns * 0.82))
    local height = math.max(12, math.floor((vim.o.lines - vim.o.cmdheight) * 0.78))
    local row = math.floor((vim.o.lines - height) / 2) - 1
    local col = math.floor((vim.o.columns - width) / 2)
    local border = (vim.o.winborder and vim.o.winborder ~= "") and vim.o.winborder or "rounded"

    local pane = group.panes[1]
    local need_start = not (pane and is_valid_buf(pane.buf))
    local buf = need_start and vim.api.nvim_create_buf(false, true) or pane.buf

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.max(0, row),
      col = math.max(0, col),
      style = "minimal",
      border = border,
      title = string.format(" [%s] %s ", group.name, short_path(group.cwd)),
      title_pos = "center",
    })
    configure_term_win(win)

    if need_start then
      local cmd = default_shell()
      vim.bo[buf].bufhidden = "hide"
      vim.bo[buf].buflisted = false
      local job_id = vim.fn.jobstart(cmd, { term = true, cwd = group.cwd })
      pane = {
        buf = buf,
        win = win,
        job_id = job_id,
        title = shell_title(cmd),
        ratio = 1,
        repl = false,
        cwd = group.cwd,
        auto_close = true,
        exited = false,
      }
      group.panes = { pane }
      configure_term_keymaps(buf)
    else
      pane.win = win
    end

    refresh_winbars()
    if focus ~= false and not pane.exited then
      vim.cmd.startinsert()
    end
    return
  end

  -- Hide any other visible split group first
  if active_group_id and active_group_id ~= group.id then
    M.hide(active_group_id)
  end

  local col_width = math.max(MIN_WIDTH, math.min(vim.o.columns - 20, math.floor(vim.o.columns * group.width)))
  local specs = pane_specs
  if #group.panes == 0 and (not specs or #specs == 0) then
    local cmd = default_shell()
    specs = { { title = shell_title(cmd), cmd = cmd, ratio = 1, repl = false, auto_close = true } }
  end

  if #group.panes == 0 then
    for i, sp in ipairs(specs) do
      if i == 1 then
        vim.cmd("botright vertical split")
        vim.api.nvim_win_set_width(0, col_width)
      else
        vim.cmd("belowright split")
      end
      local cmd = sp.cmd or default_shell()
      local pane = {
        title = sp.title or shell_title(cmd),
        ratio = sp.ratio or (1 / #specs),
        repl = sp.repl == true,
        cwd = sp.cwd or group.cwd,
        auto_close = sp.auto_close ~= false,
      }
      start_pane_in_current_win(pane, cmd)
      table.insert(group.panes, pane)
    end
  else
    for i, pane in ipairs(group.panes) do
      if i == 1 then
        vim.cmd("botright vertical split")
        vim.api.nvim_win_set_width(0, col_width)
      else
        vim.cmd("belowright split")
      end
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, pane.buf)
      configure_term_win(win)
      pane.win = win
    end
  end

  apply_pane_ratios(group)
  active_group_id = group.id
  last_group_id = group.id

  local focus_pane = group.panes[group.last_pane_idx] or group.panes[1]
  if focus == false then
    local editor_win = find_editor_win()
    if editor_win then
      pcall(vim.api.nvim_set_current_win, editor_win)
    end
  elseif focus_pane and is_valid_win(focus_pane.win) then
    vim.api.nvim_set_current_win(focus_pane.win)
    if not focus_pane.exited then
      vim.cmd.startinsert()
    end
  end
  refresh_winbars()
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function M.toggle(id)
  -- If no explicit slot requested and currently inside the floating terminal, hide float
  if not id then
    local cur_group = find_by_buf(vim.api.nvim_get_current_buf())
    if cur_group and cur_group.is_float then
      M.hide(FLOAT_ID)
      return
    end
    if active_group_id and is_group_visible(groups[active_group_id]) then
      M.hide(active_group_id)
      return
    end
    id = last_group_id or "1"
  else
    id = tostring(id)
  end

  if active_group_id == id and is_group_visible(groups[id]) then
    M.hide(id)
    return
  end

  local group = ensure_group(id)
  open_group_windows(group, nil, true)
end

function M.toggle_float()
  local group = groups[FLOAT_ID]
  if group and is_group_visible(group) then
    M.hide(FLOAT_ID)
    return
  end
  group = ensure_group(FLOAT_ID, { name = "float", is_float = true })
  open_group_windows(group, nil, true)
end

function M.split_pane(opts)
  opts = opts or {}
  local cur_buf = vim.api.nvim_get_current_buf()
  local group, cur_pane, cur_idx = find_by_buf(cur_buf)
  if not group or group.is_float then
    M.toggle_float()
    return
  end

  local cmd = opts.cmd or default_shell()
  local cwd = opts.cwd or (cur_pane and cur_pane.cwd) or group.cwd
  local col_width = is_valid_win(cur_pane and cur_pane.win) and vim.api.nvim_win_get_width(cur_pane.win) or nil

  vim.cmd("belowright split")
  local pane = {
    title = opts.title or shell_title(cmd),
    ratio = opts.ratio or 0.5,
    repl = opts.repl == true,
    cwd = cwd,
    auto_close = opts.auto_close ~= false,
  }
  start_pane_in_current_win(pane, cmd)
  table.insert(group.panes, (cur_idx or #group.panes) + 1, pane)
  group.last_pane_idx = (cur_idx or #group.panes) + 1

  if col_width then
    pcall(vim.api.nvim_win_set_width, pane.win, col_width)
  end
  snapshot_layout(group)
  refresh_winbars()
  vim.cmd.startinsert()
end

function M.context_shift_t()
  local group = find_by_buf(vim.api.nvim_get_current_buf())
  if group and not group.is_float then
    M.split_pane()
  else
    M.toggle_float()
  end
end

---@param spec { id: string, name?: string, cwd?: string, width?: number, panes: table[], toggle?: boolean, focus?: boolean }
---@return TermGroup
function M.open_workspace(spec)
  local id = tostring(spec.id)
  local existing = groups[id]
  if existing then
    prune_group(existing)
    existing = groups[id]
  end

  if existing and spec.toggle and active_group_id == id and is_group_visible(existing) then
    M.hide(id)
    return existing
  end

  local group = ensure_group(id, {
    name = spec.name or id,
    cwd = spec.cwd,
    width = spec.width,
    is_float = false,
  })
  open_group_windows(group, spec.panes, spec.focus)
  return group
end

function M.get_group(id)
  local group = groups[tostring(id)]
  if group and prune_group(group) then
    return group
  end
  return nil
end

function M.get_repl_pane(id)
  local group = M.get_group(id)
  if not group then
    return nil
  end
  for _, pane in ipairs(group.panes) do
    if pane.repl and is_valid_buf(pane.buf) and pane.job_id and not pane.exited then
      return pane, group
    end
  end
  local first = group.panes[1]
  if first and is_valid_buf(first.buf) and first.job_id and not first.exited then
    return first, group
  end
  return nil
end

function M.send(id, text)
  local pane = M.get_repl_pane(id)
  if not pane then
    return false
  end
  vim.api.nvim_chan_send(pane.job_id, text)
  -- Scroll REPL window to bottom so output stays visible
  if is_valid_win(pane.win) then
    local last = vim.api.nvim_buf_line_count(pane.buf)
    pcall(vim.api.nvim_win_set_cursor, pane.win, { last, 0 })
  end
  return true
end

function M.flash_lines(buf, start_lnum, end_lnum)
  if not is_valid_buf(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, eval_ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local s = math.max(1, math.min(start_lnum, line_count))
  local e = math.max(s, math.min(end_lnum, line_count))
  for row = s - 1, e - 1 do
    vim.api.nvim_buf_set_extmark(buf, eval_ns, row, 0, {
      line_hl_group = "TermEvalFlash",
      priority = 150,
    })
  end
  vim.defer_fn(function()
    if is_valid_buf(buf) then
      vim.api.nvim_buf_clear_namespace(buf, eval_ns, 0, -1)
    end
  end, 160)
end

local function destroy_pane(group, pane, idx)
  if pane.job_id and not pane.exited then
    pcall(vim.fn.jobstop, pane.job_id)
  end
  if is_valid_win(pane.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
    pcall(vim.api.nvim_win_close, pane.win, true)
  end
  if is_valid_buf(pane.buf) then
    pcall(vim.api.nvim_buf_delete, pane.buf, { force = true })
  end
  table.remove(group.panes, idx)
  local alive = prune_group(group)
  if not alive then
    local editor_win = find_editor_win()
    if editor_win then
      pcall(vim.api.nvim_set_current_win, editor_win)
    end
  else
    snapshot_layout(group)
  end
  refresh_winbars()
end

function M.close_pane(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local group, pane, idx = find_by_buf(buf)
  if not group or not pane then
    return
  end

  if not pane.exited then
    local choice = vim.fn.confirm(
      ("Close running terminal pane '%s' in [%s]?"):format(pane.title, group.name),
      "&Yes\n&No",
      2
    )
    if choice ~= 1 then
      return
    end
  end
  destroy_pane(group, pane, idx)
end

function M.kill_group(id, force)
  local group = groups[tostring(id)]
  if not group then
    return false
  end
  local has_running = false
  for _, pane in ipairs(group.panes) do
    if not pane.exited then
      has_running = true
      break
    end
  end
  if has_running and not force then
    local choice = vim.fn.confirm(
      ("Kill terminal group [%s] (%d pane%s)?"):format(group.name, #group.panes, #group.panes == 1 and "" or "s"),
      "&Yes\n&No",
      2
    )
    if choice ~= 1 then
      return false
    end
  end

  for i = #group.panes, 1, -1 do
    destroy_pane(group, group.panes[i], i)
  end
  return true
end

function M.rename_group(id, new_name)
  local group = groups[tostring(id)]
  if not group or not new_name or vim.trim(new_name) == "" then
    return
  end
  group.name = vim.trim(new_name)
  refresh_winbars()
end

function M.navigate(dir, from_term)
  if from_term then
    vim.cmd.stopinsert()
  end
  vim.cmd("wincmd " .. dir)
  if from_term then
    local cur_buf = vim.api.nvim_get_current_buf()
    local _, pane = find_by_buf(cur_buf)
    if pane and not pane.exited then
      vim.cmd.startinsert()
    end
  end
end

-- ---------------------------------------------------------------------------
-- Interactive Group Manager (<leader>tt via Snacks.picker)
-- ---------------------------------------------------------------------------

local function picker_items()
  local items = {}
  local ids = vim.deepcopy(group_order)
  if groups[FLOAT_ID] then
    table.insert(ids, FLOAT_ID)
  end

  for _, id in ipairs(ids) do
    local group = groups[id]
    if group and prune_group(group) then
      local titles = {}
      for _, p in ipairs(group.panes) do
        table.insert(titles, p.title)
      end
      local active = (id == active_group_id and is_group_visible(group))
        or (group.is_float and is_group_visible(group))
      local preview_pane = group.panes[group.last_pane_idx] or group.panes[1]
      local label = string.format(
        "%s [%s] (%d)  %s  %s",
        active and "●" or " ",
        group.name,
        #group.panes,
        table.concat(titles, ", "),
        short_path(group.cwd)
      )
      table.insert(items, {
        text = label,
        group = group,
        active = active,
        titles = table.concat(titles, ", "),
        cwd = short_path(group.cwd),
        buf = preview_pane and preview_pane.buf or nil,
        file = preview_pane and vim.api.nvim_buf_get_name(preview_pane.buf) or nil,
      })
    end
  end
  return items
end

function M.pick_groups()
  local function reopen_picker()
    vim.schedule(M.pick_groups)
  end

  Snacks.picker.pick({
    title = "Terminals (<CR> open · <C-r> rename · <C-d> kill · <C-n> new)",
    finder = picker_items,
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { item.active and "● " or "  ", item.active and "DiagnosticOk" or "Comment" }
      ret[#ret + 1] = { "[" .. item.group.name .. "] ", "Title" }
      ret[#ret + 1] = { ("(%d) "):format(#item.group.panes), "Number" }
      ret[#ret + 1] = { item.titles .. "  ", "Normal" }
      ret[#ret + 1] = { item.cwd, "Comment" }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.group.is_float then
        if not is_group_visible(item.group) then
          M.toggle_float()
        else
          local p = item.group.panes[1]
          if p and is_valid_win(p.win) then
            vim.api.nvim_set_current_win(p.win)
            if not p.exited then
              vim.cmd.startinsert()
            end
          end
        end
      else
        if active_group_id == item.group.id and is_group_visible(item.group) then
          local p = item.group.panes[item.group.last_pane_idx] or item.group.panes[1]
          if p and is_valid_win(p.win) then
            vim.api.nvim_set_current_win(p.win)
            if not p.exited then
              vim.cmd.startinsert()
            end
          end
        else
          M.toggle(item.group.id)
        end
      end
    end,
    actions = {
      rename_group = function(picker, item)
        if not item then
          return
        end
        picker:close()
        vim.ui.input({ prompt = "Rename terminal group: ", default = item.group.name }, function(input)
          if input and vim.trim(input) ~= "" then
            M.rename_group(item.group.id, input)
          end
          reopen_picker()
        end)
      end,
      kill_group = function(picker, item)
        if not item then
          return
        end
        picker:close()
        M.kill_group(item.group.id, false)
        if #picker_items() > 0 then
          reopen_picker()
        end
      end,
      new_group = function(picker)
        picker:close()
        vim.ui.input({ prompt = "New terminal group name: " }, function(input)
          if input and vim.trim(input) ~= "" then
            local name = vim.trim(input)
            M.toggle(name)
          end
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-r>"] = { "rename_group", mode = { "n", "i" } },
          ["<C-d>"] = { "kill_group", mode = { "n", "i" } },
          ["<C-n>"] = { "new_group", mode = { "n", "i" } },
        },
      },
    },
  })
end

-- ---------------------------------------------------------------------------
-- Autocmds & Setup
-- ---------------------------------------------------------------------------

local function percent_decode(str)
  return (str:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

function M.setup()
  setup_highlights()

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = augroup,
    callback = setup_highlights,
  })
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "ThemeChanged",
    callback = setup_highlights,
  })

  -- Track last focused editor window & refresh terminal winbars/links
  vim.api.nvim_create_autocmd("WinEnter", {
    group = augroup,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if is_editor_win(win) then
        last_editor_win = win
      else
        local group, _, idx = find_by_buf(vim.api.nvim_win_get_buf(win))
        if group and idx then
          group.last_pane_idx = idx
        end
      end
      refresh_winbars()
      update_link_highlights(win)
    end,
  })

  -- Clean formatting for any terminal buffer (even manually opened :terminal)
  vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    callback = function(ev)
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_buf(win) == ev.buf then
        configure_term_win(win)
      end
      if not find_by_buf(ev.buf) then
        configure_term_keymaps(ev.buf)
      end
    end,
  })

  -- Handle clean exit vs error exit
  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function(ev)
      local code = vim.v.event and vim.v.event.status or 0
      local group, pane, idx = find_by_buf(ev.buf)
      if not group or not pane then
        return
      end
      pane.exited = true
      pane.exit_code = code
      if pane.auto_close and code == 0 then
        vim.schedule(function()
          local g, p, i = find_by_buf(ev.buf)
          if g and p and i then
            destroy_pane(g, p, i)
          end
        end)
      else
        vim.schedule(function()
          refresh_winbars()
          if is_valid_win(pane.win) then
            update_link_highlights(pane.win)
          end
        end)
      end
    end,
  })

  -- OSC 7 (live CWD sync) & OSC 133 (prompt boundaries for gq)
  vim.api.nvim_create_autocmd("TermRequest", {
    group = augroup,
    callback = function(ev)
      local seq = ev.data and ev.data.sequence or ""
      local osc7 = seq:match("^\027%]7;file://[^/]*(/.*)$")
      if osc7 then
        local dir = percent_decode(osc7)
        if vim.fn.isdirectory(dir) == 1 then
          local _, pane = find_by_buf(ev.buf)
          if pane then
            pane.cwd = dir
            refresh_winbars()
          end
        end
        return
      end

      if seq:match("^\027%]133;A") then
        local lnum = ev.data.cursor and ev.data.cursor[1]
        if lnum then
          local prompts = vim.b[ev.buf].term_prompts or {}
          table.insert(prompts, lnum)
          vim.b[ev.buf].term_prompts = prompts
        end
      elseif seq:match("^\027%]133;C") then
        local lnum = ev.data.cursor and ev.data.cursor[1]
        if lnum then
          vim.b[ev.buf].term_last_output_start = lnum
        end
      end
    end,
  })

  -- Auto-underline jumpable links & paths when in terminal Normal mode
  vim.api.nvim_create_autocmd({ "ModeChanged", "WinScrolled", "BufEnter" }, {
    group = augroup,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if is_term_buf(vim.api.nvim_win_get_buf(win)) then
        update_link_highlights(win)
      end
    end,
  })

  -- Global terminal-mode escape (<C-Space> with <C-@> fallback for non-extkeys)
  vim.keymap.set("t", "<C-Space>", [[<C-\><C-n>]], { silent = true, desc = "Terminal normal mode" })
  vim.keymap.set("t", "<C-@>", [[<C-\><C-n>]], { silent = true, desc = "Terminal normal mode" })
end

return M
