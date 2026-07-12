# Shared themes

Palette files in `palettes/` are the only color source of truth. They contain
semantic `#RRGGBB` colors and no application-specific syntax.

```lua
return {
  name = "example",
  appearance = "dark",
  accent = "blue",
  transparent = false,
  colors = {
    -- Include every role required by schema.lua.
  },
}
```

Validate and activate palettes with:

```sh
dot-theme validate example
dot-theme set example
```

Generated adapters are written below `$XDG_CACHE_HOME/dotfiles/themes`; the
selected name is stored at `$XDG_STATE_HOME/dotfiles/theme`. Application
configuration directories receive ignored symlinks to the active generated
files.

Set `QUICKSHELL_THEME_DIR` to the QML module directory in a named Quickshell
configuration. `dot-theme set` will link `Theme.qml` and `qmldir` there, making
the singleton available as `Theme`.
