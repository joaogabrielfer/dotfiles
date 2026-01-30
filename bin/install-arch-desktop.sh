#!/usr/bin/env bash

source $DOT_DIR/bin/cmds.sh

PKGS=("audacity" "discord-canary" "ghostty" "hypridle" "hyprland" "hyprlock" "hyprpaper" "hyprshot" "mpv" "spotify" "thunar" "vlc" "waybar" "waypaper" "wireplumber" "zen-browser-bin" "swww")

if check_if_updates; then
	update_pacman 
fi

for pkg in "${PKGS[@]}"; do
	if ! check_if_present $pkg; then
		install_package_paru $pkg
	else
		echo -e "\033[34m$pkg\033[0m is already installed"
	fi
done
echo
