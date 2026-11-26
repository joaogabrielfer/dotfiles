local M = {}

local link_ns = vim.api.nvim_create_namespace("dotfiles.term.links")
local hint_ns = vim.api.nvim_create_namespace("dotfiles.term.hints")
local eval_ns = vim.api.nvim_create_namespace("dotfiles.term.eval")
local augroup = vim.api.nvim_create_augroup("dotfiles.terminal", { clear = true })

local DEFAULT_WIDTH = 0.42
local DEFAULT_HEIGHT = 0.35
local MIN_WIDTH = 30
local MIN_HEIGHT = 6
local ZOOM_RATIO = 0.82
local FLOAT_ID = "float"
local POSITIONS = { "right", "bottom", "left" }

---@class TermPane
---@field buf integer
---@field win integer?
---@field job_id integer?
---@field title string
---@field ratio number
---@field default_ratio number?
---@field repl boolean
---@field cwd string
---@field auto_close boolean
---@field exited boolean
---@field exit_code integer?

---@class TermGroup
---@field id string
---@field name string
---@field is_float boolean
---@field position "right"|"bottom"|"left"
---@field width number
---@field height number
---@field default_width number
---@field default_height number
---@field zoomed boolean
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
---@type { tab: integer, win: integer, winrestcmd: string, hid_group_id: string? }?
local editor_zoom = nil

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

local function project_root_or_cwd()
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
    vim.api.nvim_set_hl(0, "TermPromptEdit", { bg = c.surface0 })
  else
    vim.api.nvim_set_hl(0, "TermBarActive", { link = "Visual" })
    vim.api.nvim_set_hl(0, "TermBarTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "TermBarInactive", { link = "Comment" })
    vim.api.nvim_set_hl(0, "TermBarFill", { link = "StatusLine" })
    vim.api.nvim_set_hl(0, "TermLink", { underline = true })
    vim.api.nvim_set_hl(0, "TermHint", { link = "IncSearch" })
    vim.api.nvim_set_hl(0, "TermEvalFlash", { link = "Visual" })
    vim.api.nvim_set_hl(0, "TermPromptEdit", { link = "CursorLine" })
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
          local zoom_tag = group.zoomed and " [Z]" or ""
          local left = string.format(
            "%s [%s] %s (%d/%d)%s%s %%#TermBarFill#",
            title_hl,
            escape_stl(group.name),
            escape_stl(pane.title),
            idx,
            total,
            escape_stl(status),
            zoom_tag
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
    vim.wo[target_win].winfixbuf = false
    vim.wo[target_win].winfixwidth = false
    vim.wo[target_win].winfixheight = false
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

local function dock_mode_for_group(group)
  if not group then
    return "vertical"
  end
  if group.is_float then
    return "float"
  end
  if group.position == "bottom" then
    return "bottom"
  end
  return "vertical"
end

local function is_horizontal_dock(group)
  return group ~= nil and not group.is_float and group.position == "bottom"
end

local function set_win_buf(win, buf)
  vim.wo[win].winfixbuf = false
  vim.api.nvim_win_set_buf(win, buf)
end

local function configure_term_win(win, dock_mode)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].scrolloff = 0
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].cursorline = false
  vim.wo[win].winfixbuf = true
  if dock_mode == "bottom" then
    vim.wo[win].winfixwidth = false
    vim.wo[win].winfixheight = true
  elseif dock_mode == "float" then
    vim.wo[win].winfixwidth = false
    vim.wo[win].winfixheight = false
  else
    vim.wo[win].winfixwidth = true
    vim.wo[win].winfixheight = false
  end
end

local FISH_SNAPSHOT_SEQ = "\27[23;8~"
local FISH_APPLY_SEQ = "\27[24;8~"

local function request_fish_cmdline(buf, wait_ms)
  if not is_valid_buf(buf) or not vim.b[buf].term_fish_pid or not vim.b[buf].term_at_prompt then
    return false
  end
  local ch = vim.bo[buf].channel
  if not ch or ch <= 0 then
    return false
  end
  local prev_seq = vim.b[buf].term_fish_seq or 0
  pcall(vim.api.nvim_chan_send, ch, FISH_SNAPSHOT_SEQ)
  if wait_ms and wait_ms > 0 then
    vim.wait(wait_ms, function()
      return is_valid_buf(buf) and (vim.b[buf].term_fish_seq or 0) ~= prev_seq
    end, 2)
  end
  return true
end

local function is_on_active_fish_prompt(buf, win, allow_anywhere)
  if not is_valid_buf(buf) or not is_valid_win(win) then
    return false
  end
  if not vim.b[buf].term_fish_pid or not vim.b[buf].term_at_prompt then
    return false
  end
  local ppos = vim.b[buf].term_prompt_pos
  if not ppos then
    return false
  end
  if allow_anywhere then
    return true
  end
  local cur_row = vim.api.nvim_win_get_cursor(win)[1]
  return cur_row >= ppos[1]
end

local function cursor_to_fish_offset(lines, row, col0)
  local offset = 0
  for i = 1, row - 1 do
    offset = offset + vim.fn.strchars(lines[i] or "") + 1
  end
  local cur_line = lines[row] or ""
  local prefix = cur_line:sub(1, math.min(col0, #cur_line))
  return offset + vim.fn.strchars(prefix)
end

local function fish_offset_to_cursor(lines, offset)
  local rem = math.max(0, offset or 0)
  for i, line in ipairs(lines) do
    local len = vim.fn.strchars(line)
    if rem <= len then
      local byte_col = vim.fn.byteidx(line, rem)
      if byte_col < 0 then
        byte_col = #line
      end
      return i, byte_col
    end
    rem = rem - len - 1
  end
  local last = math.max(1, #lines)
  return last, #(lines[last] or "")
end

local function map_term_pos_to_overlay(term_row, term_col0, prompt_lnum, prompt_col, cmd_lines)
  local ov_row = math.max(1, math.min(#cmd_lines, term_row - prompt_lnum + 1))
  local ov_col0 = (ov_row == 1) and math.max(0, term_col0 - prompt_col) or math.max(0, term_col0)
  local line_len = #(cmd_lines[ov_row] or "")
  if line_len == 0 then
    ov_col0 = 0
  else
    ov_col0 = math.min(ov_col0, math.max(0, line_len - 1))
  end
  return ov_row, ov_col0
end

local function open_prompt_editor(term_buf, term_win, opts)
  opts = opts or {}
  if not is_on_active_fish_prompt(term_buf, term_win, opts.allow_anywhere) then
    return false
  end

  if vim.b[term_buf].term_fish_cmdline == nil or opts.refresh then
    request_fish_cmdline(term_buf, 80)
  end

  local fish_pid = vim.b[term_buf].term_fish_pid
  local ppos = vim.b[term_buf].term_prompt_pos
  if not fish_pid or not ppos then
    return false
  end

  local prompt_lnum, prompt_col = ppos[1], ppos[2]
  local cmd_text = vim.b[term_buf].term_fish_cmdline or ""
  local cmd_lines = vim.split(cmd_text, "\n", { plain = true })
  if #cmd_lines == 0 then
    cmd_lines = { "" }
  end

  -- Determine target cursor inside the overlay buffer
  local cur_r, cur_c
  if opts.use_fish_cursor then
    cur_r, cur_c = fish_offset_to_cursor(cmd_lines, vim.b[term_buf].term_fish_cursor or 0)
    local line_len = #(cmd_lines[cur_r] or "")
    if line_len > 0 and cur_c >= line_len then
      cur_c = math.max(0, line_len - 1)
    end
  else
    local tcur = vim.api.nvim_win_get_cursor(term_win)
    cur_r, cur_c = map_term_pos_to_overlay(tcur[1], tcur[2], prompt_lnum, prompt_col, cmd_lines)
  end

  -- Ensure the prompt row is visible on screen
  local sp = vim.fn.screenpos(term_win, prompt_lnum, prompt_col + 1)
  if not sp or sp.row == 0 then
    local last = math.max(1, vim.api.nvim_buf_line_count(term_buf))
    pcall(vim.api.nvim_win_set_cursor, term_win, { last, 0 })
    vim.cmd.redraw()
    sp = vim.fn.screenpos(term_win, prompt_lnum, prompt_col + 1)
    if not sp or sp.row == 0 then
      return false
    end
  end

  local win_pos = vim.api.nvim_win_get_position(term_win)
  local win_width = vim.api.nvim_win_get_width(term_win)
  local ov_col = math.max(0, sp.col - 1)
  local ov_width = math.max(12, (win_pos[2] + win_width) - ov_col)
  local base_row = math.max(0, sp.row - 1)

  local ov_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ov_buf].buftype = "nofile"
  vim.bo[ov_buf].bufhidden = "wipe"
  vim.bo[ov_buf].swapfile = false
  vim.bo[ov_buf].filetype = "fish"
  vim.api.nvim_buf_set_lines(ov_buf, 0, -1, false, cmd_lines)

  local function calc_geometry()
    local max_lines = math.max(10, vim.o.lines - vim.o.cmdheight - 1)
    local total_rows = 0
    for _, line in ipairs(vim.api.nvim_buf_get_lines(ov_buf, 0, -1, false)) do
      local w = math.max(1, vim.fn.strdisplaywidth(line))
      total_rows = total_rows + math.max(1, math.ceil(w / ov_width))
    end
    local h = math.max(1, math.min(total_rows, math.max(4, math.floor(max_lines * 0.5))))
    local r = base_row
    if r + h > max_lines then
      r = math.max(0, max_lines - h)
    end
    return r, h
  end

  local init_row, init_h = calc_geometry()
  local ov_win = vim.api.nvim_open_win(ov_buf, true, {
    relative = "editor",
    row = init_row,
    col = ov_col,
    width = ov_width,
    height = init_h,
    style = "minimal",
    border = "none",
    zindex = 60,
  })

  vim.wo[ov_win].wrap = true
  vim.wo[ov_win].linebreak = false
  vim.wo[ov_win].number = false
  vim.wo[ov_win].relativenumber = false
  vim.wo[ov_win].signcolumn = "no"
  vim.wo[ov_win].foldcolumn = "0"
  vim.wo[ov_win].cursorline = false
  vim.wo[ov_win].scrolloff = 0
  vim.wo[ov_win].winhighlight = "Normal:TermPromptEdit,EndOfBuffer:TermPromptEdit"

  pcall(vim.api.nvim_win_set_cursor, ov_win, { cur_r, cur_c })

  local done = false

  local function resize_overlay()
    if done or not is_valid_win(ov_win) or not is_valid_buf(ov_buf) then
      return
    end
    local r, h = calc_geometry()
    pcall(vim.api.nvim_win_set_config, ov_win, {
      relative = "editor",
      row = r,
      col = ov_col,
      width = ov_width,
      height = h,
    })
  end

  local function finish(execute, enter_term, leave_only)
    if done then
      return
    end
    done = true

    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
      vim.cmd.stopinsert()
    end

    local lines = is_valid_buf(ov_buf) and vim.api.nvim_buf_get_lines(ov_buf, 0, -1, false) or cmd_lines
    local cur = is_valid_win(ov_win) and vim.api.nvim_win_get_cursor(ov_win) or { 1, 0 }
    local text = table.concat(lines, "\n")
    local fish_offset = cursor_to_fish_offset(lines, cur[1], cur[2])

    if is_valid_win(ov_win) then
      pcall(vim.api.nvim_win_close, ov_win, true)
    end

    if is_valid_buf(term_buf) then
      local cmdfile = "/tmp/nvim-fish-cmd-" .. tostring(fish_pid)
      local fh = io.open(cmdfile, "w")
      if fh then
        fh:write(string.format("%d %d\n%s", execute and 1 or 0, fish_offset, text))
        fh:close()
      end
      vim.b[term_buf].term_fish_cmdline = execute and nil or text
      vim.b[term_buf].term_fish_cursor = execute and 0 or fish_offset
      local ch = vim.bo[term_buf].channel
      if ch and ch > 0 then
        pcall(vim.api.nvim_chan_send, ch, FISH_APPLY_SEQ)
      end
    end

    if not leave_only and is_valid_win(term_win) then
      pcall(vim.api.nvim_set_current_win, term_win)
      if enter_term then
        vim.cmd.startinsert()
      else
        local target_row = prompt_lnum + cur[1] - 1
        local target_col = (cur[1] == 1) and (prompt_col + cur[2]) or cur[2]
        vim.defer_fn(function()
          if is_valid_win(term_win) and is_valid_buf(term_buf) then
            local max_row = math.max(1, vim.api.nvim_buf_line_count(term_buf))
            pcall(vim.api.nvim_win_set_cursor, term_win, { math.min(target_row, max_row), target_col })
          end
        end, 30)
      end
    end
  end

  local function cancel()
    if done then
      return
    end
    done = true
    if is_valid_win(ov_win) then
      pcall(vim.api.nvim_win_close, ov_win, true)
    end
    if is_valid_win(term_win) then
      pcall(vim.api.nvim_set_current_win, term_win)
    end
  end

  local map_opts = function(desc)
    return { buffer = ov_buf, silent = true, desc = desc }
  end

  vim.keymap.set("n", "<CR>", function()
    finish(true, true, false)
  end, map_opts("Run edited prompt command"))

  vim.keymap.set({ "n", "i" }, "<C-CR>", function()
    finish(true, true, false)
  end, map_opts("Run edited prompt command"))

  vim.keymap.set({ "n", "i" }, "<C-Space>", function()
    finish(false, true, false)
  end, map_opts("Sync prompt to Fish and enter terminal mode"))

  vim.keymap.set({ "n", "i" }, "<C-@>", function()
    finish(false, true, false)
  end, map_opts("Sync prompt to Fish and enter terminal mode"))

  vim.keymap.set("n", "q", function()
    finish(false, false, false)
  end, map_opts("Sync prompt to Fish and return to normal mode"))

  vim.keymap.set("n", "<C-c>", cancel, map_opts("Cancel prompt edit"))

  local ov_group = vim.api.nvim_create_augroup("dotfiles.term.prompt_" .. ov_buf, { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "WinResized" }, {
    group = ov_group,
    buffer = ov_buf,
    callback = resize_overlay,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "BufWipeout" }, {
    group = ov_group,
    buffer = ov_buf,
    callback = function()
      if not done then
        finish(false, false, true)
      end
    end,
  })

  -- Replay Visual selection and/or triggering edit command seamlessly
  -- Note: feeding with 'i' prepends to the typeahead queue, so feed trigger BEFORE visual motion.
  if opts.feed and opts.feed ~= "" then
    local mode = opts.remap and "mi" or "ni"
    vim.api.nvim_feedkeys(opts.feed, mode, false)
  end

  if opts.visual then
    local v = opts.visual
    local r1, c1 = map_term_pos_to_overlay(v.start_pos[2], math.max(0, v.start_pos[3] - 1), prompt_lnum, prompt_col, cmd_lines)
    local r2, c2 = map_term_pos_to_overlay(v.end_pos[2], math.max(0, v.end_pos[3] - 1), prompt_lnum, prompt_col, cmd_lines)
    pcall(vim.api.nvim_win_set_cursor, ov_win, { r1, c1 })
    local target_byte = vim.fn.line2byte(r2) + c2
    if target_byte > 0 then
      vim.api.nvim_feedkeys(v.mode .. tostring(target_byte) .. "go", "ni", false)
    else
      vim.api.nvim_feedkeys(v.mode, "ni", false)
    end
  end

  return true
end

function M.edit_prompt(opts)
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "t" then
    vim.cmd.stopinsert()
  end
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  opts = vim.tbl_extend("keep", opts or {}, { allow_anywhere = true, refresh = true, use_fish_cursor = true })
  return open_prompt_editor(buf, win, opts)
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

  vim.keymap.set("n", "<M-e>", function()
    M.edit_prompt({ use_fish_cursor = false })
  end, opts("Edit terminal prompt in Neovim"))

  -- Seamless Normal-mode editing directly on the active Fish prompt line
  local normal_edit_triggers = {
    { key = "c", remap = true, reg = true },
    { key = "C", remap = false, reg = true },
    { key = "d", remap = true, reg = true },
    { key = "D", remap = false, reg = true },
    { key = "x", remap = false, reg = true },
    { key = "X", remap = false, reg = true },
    { key = "r", remap = false, reg = false },
    { key = "R", remap = false, reg = false },
    { key = "S", remap = false, reg = true },
    { key = "p", remap = false, reg = true },
    { key = "P", remap = false, reg = true },
    { key = "~", remap = false, reg = false },
    { key = "o", remap = false, reg = false },
    { key = "O", remap = false, reg = false },
    { key = "sa", remap = true, reg = false },
    { key = "sd", remap = true, reg = false },
    { key = "sr", remap = true, reg = false },
  }

  for _, trig in ipairs(normal_edit_triggers) do
    vim.keymap.set("n", trig.key, function()
      local win = vim.api.nvim_get_current_win()
      if not is_on_active_fish_prompt(buf, win, false) then
        return
      end
      local prefix = ""
      if trig.reg and vim.v.register and vim.v.register ~= "" then
        prefix = prefix .. '"' .. vim.v.register
      end
      if vim.v.count > 0 then
        prefix = prefix .. tostring(vim.v.count)
      end
      open_prompt_editor(buf, win, {
        feed = prefix .. trig.key,
        remap = trig.remap,
      })
    end, opts("Edit prompt (" .. trig.key .. ")"))
  end

  local visual_edit_triggers = {
    { key = "c", remap = true },
    { key = "d", remap = true },
    { key = "x", remap = false },
    { key = "r", remap = false },
    { key = "sa", remap = true },
    { key = "p", remap = false },
    { key = "~", remap = false },
  }

  for _, trig in ipairs(visual_edit_triggers) do
    vim.keymap.set("x", trig.key, function()
      local win = vim.api.nvim_get_current_win()
      local vmode = vim.fn.mode()
      local start_pos = vim.fn.getpos("v")
      local end_pos = vim.fn.getpos(".")
      local ppos = vim.b[buf].term_prompt_pos
      if not (vim.b[buf].term_fish_pid and vim.b[buf].term_at_prompt and ppos) then
        return
      end
      if math.min(start_pos[2], end_pos[2]) < ppos[1] then
        return
      end
      vim.cmd("normal! \27")
      open_prompt_editor(buf, win, {
        visual = {
          mode = (vmode == "V") and "V" or "v",
          start_pos = start_pos,
          end_pos = end_pos,
        },
        feed = trig.key,
        remap = trig.remap,
      })
    end, opts("Edit prompt selection (" .. trig.key .. ")"))
  end
end

local function sanitize_name(str)
  if not str then
    return ""
  end
  return vim.trim((tostring(str):gsub("%c+", "")))
end

local function avail_lines()
  return math.max(10, vim.o.lines - vim.o.cmdheight - 1)
end

local function target_col_width(ratio)
  local cols = vim.o.columns
  local min_w = math.min(MIN_WIDTH, math.max(16, math.floor(cols * 0.35)))
  local max_w = math.max(min_w, cols - math.max(16, math.floor(cols * 0.15)))
  local desired = math.floor(cols * (ratio or DEFAULT_WIDTH) + 0.5)
  return math.max(min_w, math.min(max_w, desired))
end

local function target_row_height(ratio)
  local lines = avail_lines()
  local min_h = math.min(MIN_HEIGHT, math.max(4, math.floor(lines * 0.2)))
  local max_h = math.max(min_h, lines - math.max(4, math.floor(lines * 0.15)))
  local desired = math.floor(lines * (ratio or DEFAULT_HEIGHT) + 0.5)
  return math.max(min_h, math.min(max_h, desired))
end

local function scroll_pane_to_bottom(pane)
  if not pane or not is_valid_win(pane.win) or not is_valid_buf(pane.buf) then
    return
  end
  local last = math.max(1, vim.api.nvim_buf_line_count(pane.buf))
  pcall(vim.api.nvim_win_set_cursor, pane.win, { last, 0 })
end

local function start_pane_in_win(win, pane, cmd, dock_mode)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false

  vim.api.nvim_set_current_win(win)
  set_win_buf(win, buf)

  local job_id = vim.fn.jobstart(cmd, {
    term = true,
    cwd = pane.cwd,
  })

  pane.buf = buf
  pane.win = win
  pane.job_id = job_id
  pane.exited = false
  pane.exit_code = nil

  configure_term_win(win, dock_mode)
  configure_term_keymaps(buf)
  scroll_pane_to_bottom(pane)
  return pane
end

local function start_pane_in_current_win(pane, cmd, dock_mode)
  return start_pane_in_win(vim.api.nvim_get_current_win(), pane, cmd, dock_mode)
end

local function snapshot_layout(group)
  if not group or group.is_float or group.zoomed then
    return
  end
  local cur_win = vim.api.nvim_get_current_win()

  if is_horizontal_dock(group) then
    local widths = {}
    local total_w = 0
    local height_rows = nil
    for idx, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) and vim.api.nvim_win_get_buf(pane.win) == pane.buf then
        local w = vim.api.nvim_win_get_width(pane.win)
        widths[idx] = w
        total_w = total_w + w
        if not height_rows then
          height_rows = vim.api.nvim_win_get_height(pane.win)
        end
        if pane.win == cur_win then
          group.last_pane_idx = idx
        end
      end
    end
    if height_rows and avail_lines() > 0 then
      group.height = math.max(0.15, math.min(0.80, height_rows / avail_lines()))
    end
    if total_w > 0 then
      for idx, w in pairs(widths) do
        group.panes[idx].ratio = w / total_w
      end
    end
    return
  end

  local heights = {}
  local total_h = 0
  local width_cols = nil

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
    group.width = math.max(0.15, math.min(0.80, width_cols / vim.o.columns))
  end
  if total_h > 0 then
    for idx, h in pairs(heights) do
      group.panes[idx].ratio = h / total_h
    end
  end
end

local function apply_pane_ratios(group)
  if group.is_float or group.zoomed or #group.panes <= 1 then
    return
  end

  if is_horizontal_dock(group) then
    local total_w = 0
    local total_ratio = 0
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        total_w = total_w + vim.api.nvim_win_get_width(pane.win)
        total_ratio = total_ratio + (pane.ratio or 1)
      end
    end
    if total_w <= 0 or total_ratio <= 0 then
      return
    end
    for i = 1, #group.panes - 1 do
      local pane = group.panes[i]
      if is_valid_win(pane.win) then
        local target_w = math.max(10, math.floor(total_w * ((pane.ratio or 1) / total_ratio) + 0.5))
        pcall(vim.api.nvim_win_set_width, pane.win, target_w)
      end
    end
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

local function apply_group_layout(group)
  if not group or not is_group_visible(group) then
    return
  end
  if group.is_float then
    local pane = group.panes[1]
    if pane and is_valid_win(pane.win) then
      local width = math.max(30, math.floor(vim.o.columns * 0.82))
      local height = math.max(10, math.floor((vim.o.lines - vim.o.cmdheight) * 0.78))
      local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
      local col = math.max(0, math.floor((vim.o.columns - width) / 2))
      pcall(vim.api.nvim_win_set_config, pane.win, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
      })
    end
    return
  end

  if group.zoomed then
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        if is_horizontal_dock(group) then
          pcall(vim.api.nvim_win_set_height, pane.win, target_row_height(ZOOM_RATIO))
        else
          pcall(vim.api.nvim_win_set_width, pane.win, target_col_width(ZOOM_RATIO))
        end
        break
      end
    end
    return
  end

  if is_horizontal_dock(group) then
    local row_height = target_row_height(group.height)
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        pcall(vim.api.nvim_win_set_height, pane.win, row_height)
      end
    end
  else
    local col_width = target_col_width(group.width)
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        pcall(vim.api.nvim_win_set_width, pane.win, col_width)
      end
    end
  end
  apply_pane_ratios(group)
end

local function open_dock_split(position, is_first, col_width, row_height)
  if is_first then
    if position == "left" then
      vim.cmd("topleft vertical split")
      vim.api.nvim_win_set_width(0, col_width)
    elseif position == "bottom" then
      vim.cmd("botright split")
      vim.api.nvim_win_set_height(0, row_height)
    else
      vim.cmd("botright vertical split")
      vim.api.nvim_win_set_width(0, col_width)
    end
  else
    if position == "bottom" then
      vim.cmd("belowright vertical split")
    else
      vim.cmd("belowright split")
    end
  end
end

local function close_group_windows(group)
  for _, pane in ipairs(group.panes) do
    if is_valid_win(pane.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      pcall(vim.api.nvim_win_close, pane.win, true)
    end
    pane.win = nil
  end
end

function M.hide(id)
  local group = groups[id]
  if not group then
    return
  end
  if not group.zoomed then
    snapshot_layout(group)
  end
  group.zoomed = false
  close_group_windows(group)
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
    local w = opts.width or DEFAULT_WIDTH
    local h = opts.height or DEFAULT_HEIGHT
    group = {
      id = id,
      name = sanitize_name(opts.name or id),
      is_float = opts.is_float == true,
      position = opts.position or "right",
      width = w,
      height = h,
      default_width = w,
      default_height = h,
      zoomed = false,
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

local function open_group_windows(group, pane_specs, focus, keep_insert)
  if is_editor_win(vim.api.nvim_get_current_win()) then
    last_editor_win = vim.api.nvim_get_current_win()
  end

  if group.is_float then
    local width = math.max(30, math.floor(vim.o.columns * 0.82))
    local height = math.max(10, math.floor((vim.o.lines - vim.o.cmdheight) * 0.78))
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
      configure_term_win(win, "float")
      configure_term_keymaps(buf)
    else
      pane.win = win
      configure_term_win(win, "float")
      scroll_pane_to_bottom(pane)
    end

    refresh_winbars()
    if focus ~= false and not pane.exited and keep_insert ~= false then
      vim.cmd.startinsert()
    end
    return
  end

  -- Hide any other visible split group first
  if active_group_id and active_group_id ~= group.id then
    M.hide(active_group_id)
  end

  local col_width = target_col_width(group.width)
  local row_height = target_row_height(group.height)
  local dock_mode = dock_mode_for_group(group)
  local specs = pane_specs
  if #group.panes == 0 and (not specs or #specs == 0) then
    local cmd = default_shell()
    specs = { { title = shell_title(cmd), cmd = cmd, ratio = 1, repl = false, auto_close = true } }
  end

  if #group.panes == 0 then
    -- Create all split windows and apply exact dimensions BEFORE spawning jobs
    -- so TUIs like ghcid boot with their true final PTY rows & columns.
    local pending = {}
    local default_focus_idx = 1
    for i, sp in ipairs(specs) do
      open_dock_split(group.position, i == 1, col_width, row_height)
      local win = vim.api.nvim_get_current_win()
      local cmd = sp.cmd or default_shell()
      local ratio = sp.ratio or (1 / #specs)
      local pane = {
        win = win,
        title = sp.title or shell_title(cmd),
        ratio = ratio,
        default_ratio = sp.ratio,
        repl = sp.repl == true,
        cwd = sp.cwd or group.cwd,
        auto_close = sp.auto_close ~= false,
      }
      if pane.repl then
        default_focus_idx = i
      end
      table.insert(group.panes, pane)
      table.insert(pending, { win = win, pane = pane, cmd = cmd })
    end

    apply_pane_ratios(group)

    for _, entry in ipairs(pending) do
      start_pane_in_win(entry.win, entry.pane, entry.cmd, dock_mode)
    end
    group.last_pane_idx = default_focus_idx
  else
    for i, pane in ipairs(group.panes) do
      open_dock_split(group.position, i == 1, col_width, row_height)
      local win = vim.api.nvim_get_current_win()
      set_win_buf(win, pane.buf)
      configure_term_win(win, dock_mode)
      pane.win = win
      scroll_pane_to_bottom(pane)
    end
    apply_pane_ratios(group)
  end

  group.zoomed = false
  active_group_id = group.id
  last_group_id = group.id

  -- Keep unfocused panes pinned to the bottom so auto-scroll tracks live output
  local focus_pane = group.panes[group.last_pane_idx] or group.panes[1]
  for _, pane in ipairs(group.panes) do
    if pane ~= focus_pane then
      scroll_pane_to_bottom(pane)
    end
  end

  if focus == false then
    local editor_win = find_editor_win()
    if editor_win then
      pcall(vim.api.nvim_set_current_win, editor_win)
    end
  elseif focus_pane and is_valid_win(focus_pane.win) then
    vim.api.nvim_set_current_win(focus_pane.win)
    if not focus_pane.exited and keep_insert ~= false then
      vim.cmd.startinsert()
    end
  end
  refresh_winbars()
end

local function rebuild_group_windows(group, focus_in_term, keep_insert)
  close_group_windows(group)
  local editor_win = find_editor_win()
  if editor_win then
    pcall(vim.api.nvim_set_current_win, editor_win)
  end
  open_group_windows(group, nil, focus_in_term, keep_insert)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function M.toggle(id)
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "t" then
    vim.cmd.stopinsert()
  end

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

---@param step integer 1 for next, -1 for previous
---@param from_term? boolean
function M.cycle_group(step, from_term)
  local in_term_mode = from_term == true or vim.api.nvim_get_mode().mode:sub(1, 1) == "t"
  if in_term_mode then
    vim.cmd.stopinsert()
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_group, cur_pane = find_by_buf(cur_buf)
  local was_float = cur_group ~= nil and cur_group.is_float
  if was_float then
    M.hide(FLOAT_ID)
  end

  local live_ids = {}
  for _, gid in ipairs(vim.deepcopy(group_order)) do
    local g = groups[gid]
    if g and not g.is_float and prune_group(g) then
      table.insert(live_ids, gid)
    end
  end

  if #live_ids == 0 then
    local group = ensure_group("1")
    open_group_windows(group, nil, true, true)
    return
  end

  if #live_ids == 1 then
    local only = groups[live_ids[1]]
    if not is_group_visible(only) then
      local focus_term = (cur_group ~= nil) or in_term_mode
      open_group_windows(only, nil, focus_term, in_term_mode)
    else
      if in_term_mode and cur_pane and not cur_pane.exited then
        vim.cmd.startinsert()
      end
      vim.notify(
        ("Only 1 terminal group [%s] (use 2<C-t> or <leader>tt -> n for another)"):format(only.name),
        vim.log.levels.INFO
      )
    end
    return
  end

  local ref_id = (active_group_id and is_group_visible(groups[active_group_id])) and active_group_id or last_group_id
  local cur_idx = 1
  for i, gid in ipairs(live_ids) do
    if gid == ref_id then
      cur_idx = i
      break
    end
  end

  local next_idx = ((cur_idx - 1 + (step or 1)) % #live_ids) + 1
  local target = groups[live_ids[next_idx]]
  local focus_term = (cur_group ~= nil) or in_term_mode
  open_group_windows(target, nil, focus_term, in_term_mode)
end

function M.split_pane(opts)
  opts = opts or {}
  local cur_buf = vim.api.nvim_get_current_buf()
  local group, cur_pane, cur_idx = find_by_buf(cur_buf)
  if not group or group.is_float then
    M.toggle_float()
    return
  end

  if group.zoomed then
    group.zoomed = false
    group.last_pane_idx = cur_idx or group.last_pane_idx
    rebuild_group_windows(group, true, false)
    cur_pane = group.panes[group.last_pane_idx]
    cur_idx = group.last_pane_idx
  end

  local cmd = opts.cmd or default_shell()
  local cwd = opts.cwd or (cur_pane and cur_pane.cwd) or group.cwd
  local is_bottom = is_horizontal_dock(group)
  local dock_size = nil
  if cur_pane and is_valid_win(cur_pane.win) then
    dock_size = is_bottom and vim.api.nvim_win_get_height(cur_pane.win) or vim.api.nvim_win_get_width(cur_pane.win)
  end

  if is_bottom then
    vim.cmd("belowright vertical split")
  else
    vim.cmd("belowright split")
  end
  local pane = {
    title = opts.title or shell_title(cmd),
    ratio = opts.ratio or 0.5,
    repl = opts.repl == true,
    cwd = cwd,
    auto_close = opts.auto_close ~= false,
  }
  start_pane_in_current_win(pane, cmd, dock_mode_for_group(group))
  local new_idx = (cur_idx or #group.panes) + 1
  table.insert(group.panes, new_idx, pane)
  group.last_pane_idx = new_idx

  if dock_size then
    if is_bottom then
      pcall(vim.api.nvim_win_set_height, pane.win, dock_size)
    else
      pcall(vim.api.nvim_win_set_width, pane.win, dock_size)
    end
  end
  snapshot_layout(group)
  refresh_winbars()
  vim.cmd.startinsert()
end

function M.context_shift_t()
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "t" then
    vim.cmd.stopinsert()
  end
  local group = find_by_buf(vim.api.nvim_get_current_buf())
  if group and not group.is_float then
    M.split_pane()
  else
    M.toggle_float()
  end
end

---@param spec { id: string, name?: string, cwd?: string, width?: number, height?: number, position?: "right"|"bottom"|"left", panes: table[], toggle?: boolean, focus?: boolean }
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
    height = spec.height,
    position = spec.position,
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
  local was_zoomed = group.zoomed
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
  elseif was_zoomed then
    group.zoomed = false
    rebuild_group_windows(group, true, false)
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
  local clean = sanitize_name(new_name)
  if not group or clean == "" then
    return
  end
  group.name = clean
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

local function has_editor_split_on_axis(cur_win, axis)
  local cur_pos = vim.api.nvim_win_get_position(cur_win)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= cur_win and is_editor_win(win) then
      local pos = vim.api.nvim_win_get_position(win)
      if axis == "h" and pos[2] ~= cur_pos[2] then
        return true
      elseif axis == "v" and pos[1] ~= cur_pos[1] then
        return true
      end
    end
  end
  return false
end

local function resize_dock_group(group, delta_cols, delta_rows)
  if not group or group.is_float then
    return
  end
  if delta_cols and delta_cols ~= 0 and not is_horizontal_dock(group) then
    local cur_w = nil
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        cur_w = vim.api.nvim_win_get_width(pane.win)
        break
      end
    end
    if cur_w then
      local min_w = math.min(MIN_WIDTH, math.max(16, math.floor(vim.o.columns * 0.2)))
      local max_w = math.max(min_w, vim.o.columns - 16)
      local next_w = math.max(min_w, math.min(max_w, cur_w + delta_cols))
      for _, pane in ipairs(group.panes) do
        if is_valid_win(pane.win) then
          pcall(vim.api.nvim_win_set_width, pane.win, next_w)
        end
      end
      snapshot_layout(group)
    end
  elseif delta_rows and delta_rows ~= 0 and is_horizontal_dock(group) then
    local cur_h = nil
    for _, pane in ipairs(group.panes) do
      if is_valid_win(pane.win) then
        cur_h = vim.api.nvim_win_get_height(pane.win)
        break
      end
    end
    if cur_h then
      local min_h = math.min(MIN_HEIGHT, 4)
      local max_h = math.max(min_h, avail_lines() - 4)
      local next_h = math.max(min_h, math.min(max_h, cur_h + delta_rows))
      for _, pane in ipairs(group.panes) do
        if is_valid_win(pane.win) then
          pcall(vim.api.nvim_win_set_height, pane.win, next_h)
        end
      end
      snapshot_layout(group)
    end
  end
end

---@param dir "left"|"right"|"up"|"down"
---@param _from_term? boolean
function M.resize(dir, _from_term)
  local hstep = math.max(4, math.floor(vim.o.columns * 0.04))
  local vstep = math.max(2, math.floor(avail_lines() * 0.05))
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local group, pane, idx = find_by_buf(cur_buf)

  if group then
    if group.is_float then
      local cfg = vim.api.nvim_win_get_config(cur_win)
      local w = cfg.width
      local h = cfg.height
      if dir == "right" then
        w = math.min(vim.o.columns - 4, w + hstep)
      elseif dir == "left" then
        w = math.max(30, w - hstep)
      elseif dir == "down" then
        h = math.min(avail_lines() - 2, h + vstep)
      elseif dir == "up" then
        h = math.max(8, h - vstep)
      end
      pcall(vim.api.nvim_win_set_config, cur_win, {
        relative = "editor",
        width = w,
        height = h,
        row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - w) / 2)),
      })
      return
    end

    if is_horizontal_dock(group) then
      if dir == "up" then
        resize_dock_group(group, 0, vstep)
      elseif dir == "down" then
        resize_dock_group(group, 0, -vstep)
      elseif (dir == "left" or dir == "right") and #group.panes > 1 and not group.zoomed then
        local cur_w = vim.api.nvim_win_get_width(cur_win)
        local is_last = idx == #group.panes
        local delta = (dir == "right") and hstep or -hstep
        if is_last then
          delta = -delta
        end
        pcall(vim.api.nvim_win_set_width, cur_win, math.max(10, cur_w + delta))
        snapshot_layout(group)
      end
      return
    end

    -- Vertical dock ("right" or "left")
    if dir == "left" or dir == "right" then
      local grow = (group.position == "right" and dir == "left") or (group.position == "left" and dir == "right")
      resize_dock_group(group, grow and hstep or -hstep, 0)
    elseif (dir == "up" or dir == "down") and #group.panes > 1 and not group.zoomed then
      local cur_h = vim.api.nvim_win_get_height(cur_win)
      local is_last = idx == #group.panes
      local delta = (dir == "down") and vstep or -vstep
      if is_last then
        delta = -delta
      end
      pcall(vim.api.nvim_win_set_height, cur_win, math.max(3, cur_h + delta))
      snapshot_layout(group)
    end
    return
  end

  -- Editor window: if no editor split on this axis, resize the visible terminal dock
  local active = active_group_id and groups[active_group_id] or nil
  local active_visible = active and is_group_visible(active) or false

  if dir == "left" or dir == "right" then
    if not has_editor_split_on_axis(cur_win, "h") and active_visible and not is_horizontal_dock(active) then
      local grow_dock = (active.position == "right" and dir == "left") or (active.position == "left" and dir == "right")
      resize_dock_group(active, grow_dock and hstep or -hstep, 0)
      return
    end
    local at_right = vim.fn.winnr("l") == vim.fn.winnr()
    local delta = (dir == "right") and hstep or -hstep
    if at_right then
      delta = -delta
    end
    pcall(vim.api.nvim_win_set_width, cur_win, math.max(10, vim.api.nvim_win_get_width(cur_win) + delta))
  else
    if not has_editor_split_on_axis(cur_win, "v") and active_visible and is_horizontal_dock(active) then
      local grow_dock = (dir == "up")
      resize_dock_group(active, 0, grow_dock and vstep or -vstep)
      return
    end
    local at_bottom = vim.fn.winnr("j") == vim.fn.winnr()
    local delta = (dir == "down") and vstep or -vstep
    if at_bottom then
      delta = -delta
    end
    pcall(vim.api.nvim_win_set_height, cur_win, math.max(3, vim.api.nvim_win_get_height(cur_win) + delta))
  end
end

---@param dir "h"|"j"|"k"|"l"
---@param from_term? boolean
function M.move_pane(dir, from_term)
  if from_term then
    vim.cmd.stopinsert()
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local group, pane, idx = find_by_buf(cur_buf)

  if group then
    if group.is_float then
      if from_term and pane and not pane.exited then
        vim.cmd.startinsert()
      end
      return
    end

    local function swap_panes(target_idx)
      if target_idx < 1 or target_idx > #group.panes or target_idx == idx then
        return
      end
      local a = group.panes[idx]
      local b = group.panes[target_idx]
      local win_a, win_b = a.win, b.win
      group.panes[idx], group.panes[target_idx] = b, a
      if is_valid_win(win_a) and is_valid_win(win_b) then
        local mode = dock_mode_for_group(group)
        set_win_buf(win_a, b.buf)
        configure_term_win(win_a, mode)
        b.win = win_a
        set_win_buf(win_b, a.buf)
        configure_term_win(win_b, mode)
        a.win = win_b
        apply_pane_ratios(group)
        vim.api.nvim_set_current_win(a.win)
      end
      group.last_pane_idx = target_idx
      refresh_winbars()
    end

    if is_horizontal_dock(group) then
      if dir == "h" then
        swap_panes(idx - 1)
      elseif dir == "l" then
        swap_panes(idx + 1)
      elseif dir == "k" then
        snapshot_layout(group)
        group.position = "right"
        group.last_pane_idx = idx
        rebuild_group_windows(group, true, from_term == true)
        return
      end
    else
      if dir == "k" then
        swap_panes(idx - 1)
      elseif dir == "j" then
        swap_panes(idx + 1)
      elseif dir == "h" and group.position ~= "left" then
        snapshot_layout(group)
        group.position = "left"
        group.last_pane_idx = idx
        rebuild_group_windows(group, true, from_term == true)
        return
      elseif dir == "l" and group.position ~= "right" then
        snapshot_layout(group)
        group.position = "right"
        group.last_pane_idx = idx
        rebuild_group_windows(group, true, from_term == true)
        return
      end
    end

    if from_term and pane and not pane.exited then
      vim.cmd.startinsert()
    end
    return
  end

  -- Editor window: preserve docked terminal sidebar while rearranging editor splits
  local hid_id = nil
  if active_group_id and is_group_visible(groups[active_group_id]) then
    hid_id = active_group_id
    M.hide(hid_id)
  end
  vim.cmd("wincmd " .. dir:upper())
  local moved_win = vim.api.nvim_get_current_win()
  if hid_id and groups[hid_id] then
    open_group_windows(groups[hid_id], nil, false, false)
    if is_valid_win(moved_win) then
      pcall(vim.api.nvim_set_current_win, moved_win)
    end
  end
end

function M.cycle_position()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local in_term_mode = vim.api.nvim_get_mode().mode:sub(1, 1) == "t"
  if in_term_mode then
    vim.cmd.stopinsert()
  end

  local cur_group, _, cur_idx = find_by_buf(cur_buf)
  local group = nil
  local focus_in_term = false
  if cur_group and not cur_group.is_float then
    group = cur_group
    focus_in_term = true
    group.last_pane_idx = cur_idx or group.last_pane_idx
  elseif active_group_id and is_group_visible(groups[active_group_id]) then
    group = groups[active_group_id]
  end

  if not group then
    vim.notify("No visible terminal group to dock", vim.log.levels.INFO)
    return
  end

  if group.zoomed then
    group.zoomed = false
  else
    snapshot_layout(group)
  end

  local next_pos = POSITIONS[1]
  for i, pos in ipairs(POSITIONS) do
    if pos == group.position then
      next_pos = POSITIONS[(i % #POSITIONS) + 1]
      break
    end
  end
  group.position = next_pos
  rebuild_group_windows(group, focus_in_term, in_term_mode)
  vim.notify(("Terminal [%s] docked: %s"):format(group.name, group.position), vim.log.levels.INFO)
end

function M.toggle_zoom()
  local in_term_mode = vim.api.nvim_get_mode().mode:sub(1, 1) == "t"
  if in_term_mode then
    vim.cmd.stopinsert()
  end

  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local group, cur_pane, cur_idx = find_by_buf(cur_buf)

  if group then
    if group.is_float then
      return
    end
    if group.zoomed then
      group.zoomed = false
      group.last_pane_idx = cur_idx or group.last_pane_idx
      rebuild_group_windows(group, true, in_term_mode)
    else
      snapshot_layout(group)
      group.zoomed = true
      group.last_pane_idx = cur_idx or 1
      for idx, p in ipairs(group.panes) do
        if idx ~= cur_idx and is_valid_win(p.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
          pcall(vim.api.nvim_win_close, p.win, true)
          p.win = nil
        end
      end
      if cur_pane and is_valid_win(cur_pane.win) then
        if is_horizontal_dock(group) then
          pcall(vim.api.nvim_win_set_height, cur_pane.win, target_row_height(ZOOM_RATIO))
        else
          pcall(vim.api.nvim_win_set_width, cur_pane.win, target_col_width(ZOOM_RATIO))
        end
      end
      refresh_winbars()
      if in_term_mode and cur_pane and not cur_pane.exited then
        vim.cmd.startinsert()
      end
    end
    return
  end

  -- Editor pane zoom toggle
  local cur_tab = vim.api.nvim_get_current_tabpage()
  if editor_zoom and editor_zoom.tab == cur_tab then
    local saved = editor_zoom
    editor_zoom = nil
    pcall(vim.cmd, saved.winrestcmd)
    if saved.hid_group_id and groups[saved.hid_group_id] then
      open_group_windows(groups[saved.hid_group_id], nil, false, false)
    end
    if is_valid_win(saved.win) then
      pcall(vim.api.nvim_set_current_win, saved.win)
    end
    return
  end

  local non_float = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      non_float = non_float + 1
    end
  end
  if non_float <= 1 then
    vim.notify("Single window — nothing to zoom", vim.log.levels.INFO)
    return
  end

  local hid_group_id = nil
  if active_group_id and is_group_visible(groups[active_group_id]) then
    hid_group_id = active_group_id
    M.hide(hid_group_id)
  end
  if is_valid_win(cur_win) then
    pcall(vim.api.nvim_set_current_win, cur_win)
  end
  local restcmd = vim.fn.winrestcmd()
  vim.cmd("wincmd |")
  vim.cmd("wincmd _")
  editor_zoom = {
    tab = cur_tab,
    win = cur_win,
    winrestcmd = restcmd,
    hid_group_id = hid_group_id,
  }
end

function M.equalize()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local cur_group, _, cur_idx = find_by_buf(cur_buf)
  local group = (cur_group and not cur_group.is_float) and cur_group
    or (active_group_id and is_group_visible(groups[active_group_id]) and groups[active_group_id])
    or nil

  if editor_zoom and editor_zoom.tab == vim.api.nvim_get_current_tabpage() then
    editor_zoom = nil
  end

  if group then
    if group.zoomed then
      group.zoomed = false
      if cur_idx then
        group.last_pane_idx = cur_idx
      end
      rebuild_group_windows(group, cur_group ~= nil, false)
    end
    group.width = group.default_width or DEFAULT_WIDTH
    group.height = group.default_height or DEFAULT_HEIGHT
    local use_custom_defaults = #group.panes > 1
    for _, p in ipairs(group.panes) do
      if not p.default_ratio then
        use_custom_defaults = false
        break
      end
    end
    for _, p in ipairs(group.panes) do
      p.ratio = (use_custom_defaults and p.default_ratio) or (1 / math.max(1, #group.panes))
    end
    vim.cmd("wincmd =")
    apply_group_layout(group)
    refresh_winbars()
  else
    vim.cmd("wincmd =")
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
    title = "Terminals (<CR> open · r rename · d kill · n new · q close)",
    focus = "list",
    layout = {
      preset = "default",
      hidden = { "input" },
    },
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
        vim.schedule(function()
          vim.ui.input({ prompt = ("Rename [%s]: "):format(item.group.name), default = "" }, function(input)
            local clean = sanitize_name(input)
            if clean ~= "" then
              M.rename_group(item.group.id, clean)
            end
            reopen_picker()
          end)
        end)
      end,
      kill_group = function(picker, item)
        if not item then
          return
        end
        picker:close()
        vim.schedule(function()
          M.kill_group(item.group.id, false)
          if #picker_items() > 0 then
            reopen_picker()
          end
        end)
      end,
      new_group = function(picker)
        picker:close()
        vim.schedule(function()
          vim.ui.input({ prompt = "New terminal group name: ", default = "" }, function(input)
            local clean = sanitize_name(input)
            if clean ~= "" then
              M.toggle(clean)
            end
          end)
        end)
      end,
    },
    win = {
      list = {
        keys = {
          ["r"] = "rename_group",
          ["<C-r>"] = "rename_group",
          ["d"] = "kill_group",
          ["<C-d>"] = "kill_group",
          ["n"] = "new_group",
          ["<C-n>"] = "new_group",
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

  -- Keep sidebar & float dimensions proportional when outer terminal resizes
  vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
      if active_group_id and groups[active_group_id] then
        apply_group_layout(groups[active_group_id])
      end
      if groups[FLOAT_ID] and is_group_visible(groups[FLOAT_ID]) then
        apply_group_layout(groups[FLOAT_ID])
      end
      refresh_winbars()
    end,
  })

  -- Track last focused editor window & refresh terminal winbars/links
  vim.api.nvim_create_autocmd("WinEnter", {
    group = augroup,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if is_editor_win(win) then
        last_editor_win = win
      else
        local buf = vim.api.nvim_win_get_buf(win)
        local group, _, idx = find_by_buf(buf)
        if group and idx then
          group.last_pane_idx = idx
        end
        if vim.api.nvim_get_mode().mode:sub(1, 1) == "n" then
          request_fish_cmdline(buf, 0)
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

  -- OSC 7 (live CWD sync), OSC 133 (prompt boundaries), OSC 1337 (Fish prompt editing)
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
        return
      elseif seq:match("^\027%]133;B") then
        local cur = ev.data.cursor
        vim.b[ev.buf].term_at_prompt = true
        vim.b[ev.buf].term_fish_cmdline = nil
        if cur then
          vim.b[ev.buf].term_prompt_pos = { cur[1], cur[2] }
        end
        return
      elseif seq:match("^\027%]133;C") then
        vim.b[ev.buf].term_at_prompt = false
        vim.b[ev.buf].term_fish_cmdline = nil
        local lnum = ev.data.cursor and ev.data.cursor[1]
        if lnum then
          vim.b[ev.buf].term_last_output_start = lnum
        end
        return
      end

      local fish_pid = seq:match("^\027%]1337;nvim_fish=(%d+)$")
      if fish_pid then
        vim.b[ev.buf].term_fish_pid = tonumber(fish_pid)
        return
      end

      local cmd_pid, cmd_cur, cmd_enc = seq:match("^\027%]1337;nvim_cmdline=(%d+);(%d+);(.*)$")
      if cmd_pid then
        vim.b[ev.buf].term_fish_pid = tonumber(cmd_pid)
        vim.b[ev.buf].term_fish_cursor = tonumber(cmd_cur) or 0
        vim.b[ev.buf].term_fish_cmdline = percent_decode(cmd_enc)
        vim.b[ev.buf].term_fish_seq = (vim.b[ev.buf].term_fish_seq or 0) + 1
        return
      end

      local open_pid = seq:match("^\027%]1337;nvim_open_prompt=(%d+)$")
      if open_pid then
        vim.b[ev.buf].term_fish_pid = tonumber(open_pid)
        vim.schedule(function()
          if not is_valid_buf(ev.buf) then
            return
          end
          local win = vim.fn.bufwinid(ev.buf)
          if win == -1 or not is_valid_win(win) then
            return
          end
          if vim.api.nvim_get_mode().mode:sub(1, 1) == "t" then
            vim.cmd.stopinsert()
          end
          open_prompt_editor(ev.buf, win, { allow_anywhere = true, use_fish_cursor = true })
        end)
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
  local function exit_term_mode()
    local buf = vim.api.nvim_get_current_buf()
    request_fish_cmdline(buf, 0)
    local keys = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end

  vim.keymap.set("t", "<C-Space>", exit_term_mode, { silent = true, desc = "Terminal normal mode" })
  vim.keymap.set("t", "<C-@>", exit_term_mode, { silent = true, desc = "Terminal normal mode" })
end

return M
