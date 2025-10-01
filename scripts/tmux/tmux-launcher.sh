#!/usr/bin/env bash

PROJECTS_DIR="$HOME/Personal"
if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Error: Projects directory not found at '$PROJECTS_DIR'"
    read -p "Press Enter to exit"
    exit 1
fi

selected_dir=$((echo "$HOME";find "$HOME/Personal" -mindepth 1 -maxdepth 2 -type d) | fzf --reverse)

if [ -z "$selected_dir" ]; then
    exit 0
fi

session_name=$(basename "$selected_dir")

if tmux has-session -t "$session_name" 2>/dev/null; then
    exec tmux attach-session -t "$session_name"
else
    exec tmux new-session -s "$session_name" -c "$selected_dir"
fi
