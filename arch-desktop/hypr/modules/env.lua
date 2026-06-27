-- Nvidia
hl.env("LIBVA_DRIVER_NAME","nvidia")
hl.env("XDG_SESSION_TYPE","wayland")
hl.env("GBM_BACKEND","nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME","nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Dark theme
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Cursor size
hl.env("XCURSOR_SIZE","24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")
