#!/usr/bin/env bash

PROJECTS_DIR="$HOME/Personal"

if [ ! -d "$PROJECTS_DIR" ]; then
    tmux display-message "Error: Directory '$PROJECTS_DIR' not found."
    exit 1
fi

initial_selection_list=$( (
    echo "$HOME"
    find "$PROJECTS_DIR" -mindepth 1 -maxdepth 2 -type d
    echo "$HOME/.config"
	echo "new"
) | sort -u)

selected_dir=$(echo "$initial_selection_list" | fzf --prompt="Select Project: " --reverse)

if [ -z "$selected_dir" ]; then
    exit 0
fi

if [ "$selected_dir" == "$HOME/.config" ]; then
    final_dir=$(find "$HOME/.config" -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select Config Directory: " --reverse)

    if [ -z "$final_dir" ]; then
        exit 0
    fi
    session_name="config"
elif [[ "$selected_dir" == "new" ]]; then

	read -p "Insira o nome do projeto: " project_name

	if [ -z "$project_name" ]; then
		echo "No project name provided. Aborting."
		exit 1
	fi

	mkdir -p "$PROJECTS_DIR/Programming/$project_name"

	final_dir="$PROJECTS_DIR/Programming/$project_name"
	session_name_raw=$(basename "$final_dir")
	session_name=${session_name_raw#.}
else
	final_dir="$selected_dir"
	session_name_raw=$(basename "$final_dir")
	session_name=${session_name_raw#.}
fi

if [ -z "$TMUX" ]; then
	tmux new-session -s "$session_name" -c "$final_dir"
	exit 0
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
	tmux switch-client -t "$session_name"
else
	tmux new-session -d -s "$session_name" -c "$final_dir"
	tmux switch-client -t "$session_name"
fi
