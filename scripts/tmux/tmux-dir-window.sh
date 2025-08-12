#!/usr/bin/env bash

if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed. Please install it to use this script."
    exit 1
fi
SEARCH_PATHS=(
    ~/Personal/
    ~/.config
    ~ # Home directory
)

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find "${SEARCH_PATHS[@]}" -mindepth 1 -maxdepth 2 -type d | \
        sed "s|^$HOME/||" | \
        fzf --prompt="Select Project: " --height="100%" --border=rounded
    )
    if [[ -n "$selected" ]]; then
        selected="$HOME/$selected"
    fi
fi

# Exit if no directory was selected (e.g., user pressed Esc)
if [[ -z $selected ]]; then
    exit 0
fi

# Get a clean session name from the directory path (e.g., /path/to/my.project -> my_project)
selected_name=$(basename "$selected" | tr . _)

# --- Main Logic ---

# Check if we are currently inside a tmux session
if [[ -n $TMUX ]]; then
    # --- INSIDE TMUX ---
    # Create a new window in the current session with the selected directory
    tmux new-window -c "$selected" -n "$selected_name"
else
    # --- OUTSIDE TMUX ---
    # Check if a session with this name already exists
    if ! tmux has-session -t="$selected_name" 2>/dev/null; then
        # If the session doesn't exist, create it in the background
        tmux new-session -ds "$selected_name" -c "$selected"
    fi
    # Attach to the session (whether it was just created or already existed)
    tmux switch-client -t "$selected_name"
fi
