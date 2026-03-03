#!/usr/bin/env bash

if ! command -v wofi >/dev/null 2>&1; then
	/home/joaogabriel/.config/scripts/tmux/new-session.sh
else
	/home/joaogabriel/.config/wofi/scripts/tmux-launcher.sh
fi
