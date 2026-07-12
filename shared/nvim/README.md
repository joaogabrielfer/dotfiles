# Neovim configuration

This configuration targets Neovim 0.12 or newer. It uses native LSP,
Tree-sitter, diagnostics, snippets, and editor APIs where they provide the
needed behavior.

## Structure

- `lua/config/`: core options, autocmds, keymaps, LSP, and theme API.
- `lua/plugins/`: plugin specifications grouped by responsibility.
- `after/` and `syntax/`: filetype-specific behavior.
- `snippets/`: custom snippet data.
- `../themes/`: shared, application-neutral theme palettes and renderers.

Run `:Lazy`, `:Mason`, and `:checkhealth` to inspect managed dependencies.
See [`docs/refactor-report.md`](docs/refactor-report.md) for the complete list
of additions, replacements, and compatibility bindings.

## Main keymaps

| Key | Action |
| --- | --- |
| `<leader><space>` | Smart file picker |
| `<leader>ff` / `<leader>fg` | Find files / Git files |
| `<leader>sg` | Grep |
| `<leader>fb` | Buffers |
| `<leader>sd` / `<leader>sq` | Diagnostics / quickfix |
| `<leader>ss` / `<leader>sS` | Document / workspace symbols |
| `<leader>su` | Undo history |
| `<leader>sk` / `:Keymaps` | Search all keymaps |
| `<leader>?` | Show the leader-key hierarchy |
| `<leader>cf` / `<leader>cd` | Format / line diagnostics |
| `<leader>uh` | Toggle inlay hints |
| `<leader>uv` | Toggle diagnostic virtual lines |
| `<leader>ul` | Toggle code lens |
| `[d` / `]d` | Previous / next diagnostic |
| `[q` / `]q` | Previous / next quickfix item |
| `<leader>qf` | Write and open quickfix |
| `[h` / `]h` | Previous / next Git hunk |
| `-` / `_` | Oil parent / working directory |
| `<leader>ha` / `<leader>hh` | Add to Harpoon / Harpoon menu |

Neovim's native LSP mappings are retained, including `K`, `gra`, `gri`,
`grn`, `grr`, `grt`, `grx`, and `gO`.

## Themes

Palettes live in `~/dotfiles/shared/themes/palettes` and return plain Lua
tables. Use:

```vim
:Theme peach
:ThemePreview pink
:ThemePicker
:ThemeReload
```

Lua callers can use `require("config.theme").set("peach")`. The standalone
`dot-theme` command generates application theme files. Alacritty deliberately
keeps its original Catppuccin Mocha configuration and does not import the
generated palette.

```sh
dot-theme list
dot-theme validate peach
dot-theme set peach
```
