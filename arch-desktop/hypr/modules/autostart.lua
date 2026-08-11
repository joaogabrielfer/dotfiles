hl.on("hyprland.start", function()
    -- UWSM already manages the session environment.
    -- No dbus-update-activation-environment block needed here.

    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("uwsm app -- udiskie")
    hl.exec_cmd("uwsm app -- vicinae server")
    hl.exec_cmd("uwsm app -- env OBSIDIAN_VAULT=$HOME/personal/notas OBSIDIAN_VAULT_NAME=notas qs -c island_shell -n")
    -- Deprecated during the Peach Quickshell migration:
    -- hl.exec_cmd("uwsm app -- dms run")
    hl.exec_cmd("hyprpm reload")

    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
end)
