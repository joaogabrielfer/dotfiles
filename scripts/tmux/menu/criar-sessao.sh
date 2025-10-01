#!/usr/bin/env bash

PROJECTS_DIR="$HOME/Personal"

if [ ! -d "$PROJECTS_DIR" ]; then
    tmux display-message "Error: Directory '$PROJECTS_DIR' not found."
    exit 1
fi

selected_dir=$((echo "$HOME";find "$HOME/Personal" -mindepth 1 -maxdepth 2 -type d; echo "$HOME/.config") | fzf --reverse)

if [ -z "$selected_dir" ]; then
    exit 0
fi

session_name=$(basename "$selected_dir")

if [ -z "$TMUX" ]; then
    tmux new-session -s "$session_name" -c "$selected_dir"
    exit 0
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
else
    tmux new-session -d -s "$session_name" -c "$selected_dir"
    tmux switch-client -t "$session_name"
fi
