#!/usr/bin/env bash

initialClass=$(hyprctl -j activewindow | jq '.initialClass')

if [ "$initialClass" = "\"zen\"" ]; then
	hyprctl dispatch sendshortcut CTRL_SHIFT, C, activewindow
	sleep 0.1
	URL=$(wl-paste)

	hyprctl dispatch workspace empty
	sleep 0.1
	zen-browser --new-window "$URL" &
	hyprctl dispatch exec 'alacritty -e ~/.config/scripts/fzf-notes.sh'
	sleep 3
	ZEN_ADDRESS=$(hyprctl clients -j | jq -r ".[] | select(.class == \"zen\") | select(.workspace.id == $(hyprctl activeworkspace -j | jq '.id')) | .address")
	hyprctl dispatch sendshortcut CTRL_ALT, C, address:$ZEN_ADDRESS
fi
