{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Terminal
    alacritty
    ghostty

    # Desktop & Wayland
    waybar
    wofi
    swaync
    hyprlock
    hypridle
    hyprpaper
    hyprshot
    waypaper
    pyprland
    niri
    inputs.dms.packages.${pkgs.system}.default

    # Tools & Utilities
    udiskie
    fzf
    bat
    eza
    jq
    playerctl
    brightnessctl
    ddcutil
    xclip
    wl-clipboard
    fd
    ripgrep

    # Dependencies for scripts
    libnotify # For swaync-client
  ];
}