local M = {
  default = "peach",
  name = nil,
  palette = nil,
}

local theme_command = vim.fn.exepath("dot-theme")
if theme_command == "" then
  theme_command = vim.fn.expand("~/.config/scripts/dot-theme")
end
local resolved_command = vim.uv.fs_realpath(theme_command)
local default_palette_dir = resolved_command
    and vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(resolved_command)), "themes", "palettes")
  or vim.fn.expand("~/dotfiles/shared/themes/palettes")
local palette_dir = vim.env.DOTFILES_THEME_DIR or default_palette_dir
local state_root = vim.fs.joinpath(
  vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state"),
  "dotfiles"
)
local state_file = vim.fs.joinpath(state_root, "theme")

local schema_chunk = assert(loadfile(vim.fs.joinpath(vim.fs.dirname(palette_dir), "schema.lua")))
local schema = schema_chunk()

local function load(name)
  if not name:match("^[%w_-]+$") then
    return nil, "invalid theme name"
  end

  local chunk, error_message = loadfile(vim.fs.joinpath(palette_dir, name .. ".lua"))
  if not chunk then
    return nil, error_message
  end

  local ok, palette = pcall(chunk)
  if not ok then
    return nil, palette
  end
  local valid, result = pcall(schema.validate, palette, name)
  return valid and result or nil, valid and nil or result
end

local function highlights(colors, accent_name)
  local accent = colors[accent_name]
  return {
    CursorLine = { bg = colors.surface0 },
    CursorLineNr = { fg = accent, bold = true },
    DiagnosticSignError = { fg = colors.red },
    DiagnosticSignHint = { fg = colors.teal },
    DiagnosticSignInfo = { fg = colors.sky },
    DiagnosticSignWarn = { fg = colors.yellow },
    LineNr = { fg = colors.subtext0 },
    MiniStatuslineInactive = { fg = colors.overlay0, bg = colors.crust },
    MiniStatuslineModeCommand = { fg = colors.crust, bg = colors.red, bold = true },
    MiniStatuslineModeInsert = { fg = colors.crust, bg = colors.green, bold = true },
    MiniStatuslineModeNormal = { fg = colors.crust, bg = accent, bold = true },
    MiniStatuslineModeOther = { fg = colors.crust, bg = colors.teal, bold = true },
    MiniStatuslineModeReplace = { fg = colors.crust, bg = colors.maroon, bold = true },
    MiniStatuslineModeVisual = { fg = colors.crust, bg = colors.lavender, bold = true },
    ModeMsg = { fg = colors.crust, bg = accent, bold = true },
    Search = { fg = colors.crust, bg = accent },
    StatusLine = { fg = accent, bg = colors.crust },
    StatusLineNC = { fg = colors.surface1, bg = colors.crust },
    Visual = { bg = colors.overlay0 },
    WinSeparator = { fg = accent, bold = true },
  }
end

function M.apply(name)
  local palette, error_message = load(name)
  if not palette then
    return nil, error_message
  end

  vim.o.background = palette.appearance
  require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = palette.transparent == true,
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
    },
    integrations = {
      blink_cmp = true,
      gitsigns = true,
      markdown = true,
      mini = { enabled = true },
      native_lsp = { enabled = true },
      snacks = { enabled = true },
      treesitter = true,
    },
    color_overrides = { mocha = palette.colors },
    custom_highlights = function(colors)
      return highlights(colors, palette.accent)
    end,
  })
  vim.cmd.colorscheme("catppuccin")

  M.name = name
  M.palette = palette
  vim.api.nvim_exec_autocmds("User", {
    pattern = "ThemeChanged",
    data = { name = name, palette = palette },
  })
  return true
end

function M.set(name)
  local palette, error_message = load(name)
  if not palette then
    return nil, error_message
  end

  if vim.fn.executable(theme_command) == 1 then
    local result = vim.system({ theme_command, "set", name, "--no-neovim" }, { text = true }):wait()
    if result.code ~= 0 then
      return nil, vim.trim(result.stderr or result.stdout or "theme switch failed")
    end
  else
    vim.fn.mkdir(state_root, "p")
    vim.fn.writefile({ name }, state_file)
  end
  return M.apply(name)
end

function M.preview(name)
  return M.apply(name)
end

function M.reload()
  return M.apply(M.name or M.default)
end

function M.current()
  return M.name
end

function M.list()
  local names = {}
  for name, type_ in vim.fs.dir(palette_dir) do
    local stem = type_ == "file" and name:match("^(.*)%.lua$")
    if stem and stem ~= "init" then
      table.insert(names, stem)
    end
  end
  table.sort(names)
  return names
end

local function report(ok, error_message)
  if not ok then
    vim.notify("Theme: " .. tostring(error_message), vim.log.levels.ERROR)
  end
end

function M.setup(options)
  M.default = options and options.default or M.default

  vim.api.nvim_create_user_command("Theme", function(command)
    report(M.set(command.args))
  end, {
    nargs = 1,
    complete = function()
      return M.list()
    end,
  })

  vim.api.nvim_create_user_command("ThemePreview", function(command)
    report(M.preview(command.args))
  end, {
    nargs = 1,
    complete = function()
      return M.list()
    end,
  })

  vim.api.nvim_create_user_command("ThemeReload", function()
    report(M.reload())
  end, {})

  vim.api.nvim_create_user_command("ThemePicker", function()
    vim.ui.select(M.list(), { prompt = "Theme" }, function(choice)
      if choice then
        report(M.set(choice))
      end
    end)
  end, {})

  local selected = vim.env.DOTFILES_THEME
  if not selected and vim.fn.filereadable(state_file) == 1 then
    selected = vim.trim((vim.fn.readfile(state_file)[1] or ""))
  end
  selected = selected ~= "" and selected or M.default

  local ok, error_message = M.apply(selected)
  if not ok and selected ~= M.default then
    vim.notify(("Theme %q failed, using %q: %s"):format(selected, M.default, error_message), vim.log.levels.WARN)
    ok, error_message = M.apply(M.default)
  end
  report(ok, error_message)
end

return M
