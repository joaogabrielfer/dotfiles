#!/usr/bin/env bash
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed. Please install it to use this script."
    exit 1
fi
declare -A SEARCH_PATHS=(
    ["$HOME/Personal/Programming/"]="6"
    ["$HOME/"]="1"
)

find_cmds=()
for path in "${!SEARCH_PATHS[@]}"; do
    depth=${SEARCH_PATHS[$path]}
    find_cmds+=("find \"$path\" -maxdepth \"$depth\" -path '*/.git' -prune -o -path '*/node_modules' -prune -o -path '*/target' -prune -o -type f -print")
done

selected_file=$(eval "$(IFS=';'; echo "${find_cmds[*]}")" | \
    fzf --prompt="Select File: " --height="100%" --border=rounded --preview 'bat --color=always {}'
)

selected_name=$(basename "$selected_file" | tr . _)

if [[ -n "$selected_file" ]]; then
    if [[ -n $TMUX ]]; then
	cd $(dirname $selected_file)
	tmux new-window -n "nvim" "cd $selected_file;nvim $selected_file" 
    else
	if ! tmux has-session -t="$selected_name" 2>/dev/null; then
	    tmux new-session -ds "$selected_name" "nvim $selected_file"
	fi
	cd $(dirname $selected_file)
	tmux switch-client -t "neovim" "nvim $selected_file" 
    fi

else
    echo "No file selected."
fi

