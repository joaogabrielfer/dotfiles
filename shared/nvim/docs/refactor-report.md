# Neovim refactor report

## Added

- Native Neovim 0.12 LSP configuration through `vim.lsp.config()` and
  `vim.lsp.enable()`.
- Rust-only synchronous format-on-save and automatic rust-analyzer inlay
  hints. `<leader>uh` toggles hints.
- Gitsigns hunk navigation, preview, stage/reset, and current-line blame.
  Gutter signs are disabled.
- Snacks pickers for files, grep, buffers, help, diagnostics, quickfix,
  symbols, marks, jumps, undo history, and keymaps.
- WhichKey's described leader-key overlay.
- A searchable `:Keymaps` command and `<leader>sk` mapping.
- Native `vim.snippet` expansion with Friendly Snippets and the existing custom Go, ternary, and GPL snippets. - The existing nvim-treesitter configuration, parser list, Neovim 0.12 compatibility directives, and custom PASM parser.
- Shared Peach and Pink palettes, persistent theme selection, application adapters, and the `dot-theme` CLI. Alacritty remains on its original Catppuccin Mocha configuration. Native SLUR syntax highlighting.
- Global rounded floating-window borders and standard XDG undo storage.

## Replaced or removed

- Telescope and telescope-fzf-native were replaced by Snacks picker.
- Dressing was replaced by Snacks input/select.
- Undotree was replaced by the Snacks undo picker.
- LuaSnip, lspkind, and blink.compat were removed in favor of Blink v1 and
  native snippets.
- paint.nvim was replaced by `syntax/slur.vim`.
- nvim-treesitter was retained after its proposed replacement caused a Rust
  highlighting regression.
- Unused Gruvbox, Rose Pine, and Tokyo Night installations were removed.
- Duplicate lazy.nvim bootstrap, LSP mappings, snippet loading, and theme
  configuration were removed.

## Binding discovery

- Pause after pressing `<leader>` to open the WhichKey group overlay.
- Press `<leader>?` for a persistent overlay of the complete leader hierarchy.
- Press `<leader>sk` or run `:Keymaps` for a searchable list of mappings.
- Every custom mapping is expected to have a description. Undescribed entries
  in the picker generally come from Vim or plugin defaults.

## Changed bindings

These keys still exist, but their implementation or result changed:

| Key | Before | Now |
| --- | --- | --- |
| `<leader>f` | Telescope files | Snacks project-root files |
| `<leader>gg` | Telescope live grep | Snacks grep |
| `<leader>gh` | Telescope help tags | Snacks help |
| `<leader>u` | Undotree window | Searchable Snacks undo history |
| `<leader>bh` | Buffer list in quickfix | Searchable Snacks buffer history |
| `<C-g>` | Attempted centered upward scroll | Working `<C-u>zz` centered scroll |
| `<Tab>` / `<S-Tab>` | Completion selection only | Completion selection, then native snippet jump |
| `<leader>w` | `:w!` | `:write` |
| `<leader>q` | `<C-w>q` | `:close` |
| `<leader>bs` | Insert shell header, shell `chmod` | Same result without command output |
| `<leader>ch` | Shell `chmod +x` | Same result without command output |
| `<C-f>` | Shell-escaped tmux command string | Same action using an argument vector |

All other previous custom bindings were retained, including `-`, `_`,
`<leader>x`, `<leader><leader>x`, `<C-c>`, `<C-d>`, `<leader>p`,
`<leader>d`, visual `<M-h/j/k/l>`, `<leader><Tab>`, `<leader>i`, `gd`,
`gD`, `gi`, `gr`, `<leader>ca`, `<leader>b`, `<leader>bf`, `<leader>rn`,
`<leader>I`, `<leader>s`, `<C-a>`, `<leader>o`, `<A-n>`, `<A-p>`,
`<leader>a`, `<leader>h`, `<C-h/j/k/l>`, `<leader>gs`, `<leader>.`,
`<leader>S`, `<A-.>`, and `<A-,>`.

## Added bindings

| Key | Action |
| --- | --- |
| `<C-u>` | Scroll up and center |
| `<leader><space>` | Smart project file picker |
| `<leader>fb` / `<leader>ff` / `<leader>fg` / `<leader>fr` | Buffers / files / Git files / recent files |
| `<leader>sg` / `<leader>sh` / `<leader>sk` | Grep / help / keymaps |
| `<leader>sm` / `<leader>sj` | Marks / jumps |
| `<leader>sd` / `<leader>sq` | Diagnostics / quickfix picker |
| `<leader>ss` / `<leader>sS` | Document / workspace symbols |
| `<leader>su` | Undo history |
| `<leader>?` | Persistent WhichKey leader hierarchy |
| `<leader>cd` / `<leader>cf` / `<leader>cq` | Diagnostics / format / diagnostics to quickfix |
| `[d` / `]d` | Previous / next diagnostic |
| `[q` / `]q` | Previous / next quickfix item |
| `<leader>qo` / `<leader>qf` | Toggle quickfix / write and open quickfix |
| `<A-i>` | Write, open quickfix, and select its first item |
| `<leader>uv` / `<leader>uh` / `<leader>ul` | Toggle diagnostic lines / inlay hints / code lens |
| `<leader>cs` | Switch C source/header |
| `<leader>ya` | Yank the entire file to the system clipboard |
| `<leader>xs` / `<leader>xx` | Add shell template / make file executable |
| `<leader>ha` / `<leader>hh` | Add to Harpoon / open Harpoon |
| `[h` / `]h` | Previous / next Git hunk |
| `<leader>ghs` / `<leader>ghr` / `<leader>ghp` | Stage / reset / preview Git hunk |
| `<leader>gb` | Toggle current-line Git blame |
| `dd` in quickfix | Delete the selected quickfix item |

Neovim 0.12 also supplies native LSP mappings: `K`, `gra`, `gri`, `grn`,
`grr`, `grt`, `grx`, `gO`, and insert-mode `<C-s>`.

## Removed bindings

No previous custom binding was intentionally removed. Legacy keys are kept as
described aliases even where a more organized replacement was added.

## Corrections after live testing

- Restored the original nvim-treesitter configuration and pinned its previous
  working revision after the replacement regressed Rust highlighting.
- Restored Alacritty byte-for-byte to its original opacity and Catppuccin
  Mocha colors. It no longer imports the generated peach palette.
- Removed the custom brown `LspInlayHint` background. Rust inferred types
  still enable automatically and now use the colorscheme default.
- Disabled Gitsigns gutter markers while retaining hunk commands.
- File pickers search from the project root and display path-first names such
  as `src/main.rs`.
- Excluded the externally installed Gleam server from Mason's install list,
  while retaining its native LSP configuration.
