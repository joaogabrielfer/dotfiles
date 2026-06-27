hl.on("hyprland.start", function ()
  hl.exec_cmd([[
        sh -c '
            dbus-update-activation-environment --systemd \
                WAYLAND_DISPLAY \
                XDG_CURRENT_DESKTOP \
                HYPRLAND_INSTANCE_SIGNATURE \
                XDG_RUNTIME_DIR

            systemctl --user import-environment \
                WAYLAND_DISPLAY \
                XDG_CURRENT_DESKTOP \
                HYPRLAND_INSTANCE_SIGNATURE \
                XDG_RUNTIME_DIR

            pkill -f dms
            pkill -f quickshell
        '
    ]])
  -- hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("dms run")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("swaync")
  hl.exec_cmd("udiskie")
  hl.exec_cmd("systemctl --user restart pipewire pipewire-pulse wireplumber")
  hl.exec_cmd("vicinae server")
  -- dark theme
  hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
  -- pretty stuff
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)
