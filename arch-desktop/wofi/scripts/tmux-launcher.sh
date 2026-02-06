#!/usr/bin/env bash

PERSONAL_DIR="$HOME/personal"
PROGRAMMING_DIR="$HOME/personal/programming/"

CSS="$HOME/.config/wofi/styles.css"
WOFI_BASE="wofi --dmenu --style $CSS --width 25% --height 40% --prompt 'Mudar para:'"
terminal="alacritty"

wofi_input() {
    wofi --dmenu --width 400 --height 50 --style $CSS --prompt "$1" --cache-file /dev/null
}

initial_list=$( (
    (
        echo "home"
        echo "config"
		echo "personal"
		echo "programming"
		) ) )

selected_display=$(echo "$initial_list" | $WOFI_BASE --prompt "Selecionar Projeto:")
[ -z "$selected_display" ] && exit 0

if [ "$selected_display" == "home" ]; then
    selected_dir="$HOME"
else
    selected_dir="${selected_display//\~/$HOME}"
fi

if [ "$selected_dir" == "config" ]; then
    dirs=$( (
        echo "dotfiles"
        fd . -td -tl "$HOME/.config" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/arch-desktop" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/shared" --max-depth 1 --exec echo {/}
    ) | sed 's/\/$//' | sort -u )

    final_display_dir=$(echo "$dirs" | $WOFI_BASE --prompt "Pasta de Config:")
    [ -z "$final_display_dir" ] && exit 0
    
    if [ "$final_display_dir" == "dotfiles" ]; then
        final_dir="$HOME/dotfiles"
    elif [ -d "$HOME/.config/$final_display_dir" ]; then
        final_dir="$HOME/.config/$final_display_dir"
    elif [ -d "$HOME/dotfiles/arch-desktop/$final_display_dir" ]; then
        final_dir="$HOME/dotfiles/arch-desktop/$final_display_dir"
    elif [ -d "$HOME/dotfiles/shared/$final_display_dir" ]; then
        final_dir="$HOME/dotfiles/shared/$final_display_dir"
    else
        final_dir="$HOME/.config/$final_display_dir"
    fi

    session_name="config/$(basename "$final_dir")"

elif [[ "$selected_display" == "new project" ]]; then
    prog_dir="$PROJECTS_DIR/Programming"
    category_display=$(fd . "$prog_dir" --max-depth 1 --type d | sed "s|^$HOME|~|" | $WOFI_BASE --prompt "Categoria:")
    [ -z "$category_display" ] && exit 0
    
    category_path="${category_display//\~/$HOME}"
    project_name=$(echo "" | wofi_input "Nome do novo projeto:")
    [ -z "$project_name" ] && exit 1

    final_dir="$category_path/$project_name"
    mkdir -p "$final_dir"
    session_name=${project_name#.}

elif [[ "$selected_dir" == "programming" ]]; then
	selection=$((
		fd . -td -tl "$PROGRAMMING_DIR" --min-depth 2 --max-depth 2
		echo "tmp"
		) | sed -E 's/^\/.*(\/.*\/.*\/)/\1/' | sed -E 's/^\/(.*)\/$/\1/' | sed -E 's/^tmp\/.*$//' | sed '/^[[:blank:]]*$/d' | $WOFI_BASE --prompt "Projeto:")

    [ -z "$selection" ] && exit 0
    
    final_dir="$PROGRAMMING_DIR$selection"
    mkdir -p "$final_dir"
    session_name=$selection
elif [[ "$selected_dir" == "personal" ]]; then
	selection=$((
		fd . -td -tl "$PERSONAL_DIR" --max-depth 2
		) | sed -E 's/^\/.*(\/.*\/.*\/)/\1/' | sed -E 's/^\/(.*)\/$/\1/' | sed -E 's/^.*programming.*//' | sed '/^[[:blank:]]*$/d' | $WOFI_BASE --prompt "Projeto:")

    [ -z "$selection" ] && exit 0
    
    final_dir="$HOME/$selection"
    mkdir -p "$final_dir"
    session_name=$selection
elif [[ "$selected_dir" == "$HOME" ]]; then
	final_dir="$selected_dir"
	session_name="home"
else 
    final_dir="$selected_dir"
    session_name=$(basename "$final_dir" | sed 's/^\.//')
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
    new_name=$(echo "${session_name}-2" | wofi_input "Sessão já existe! Novo nome:")
    session_name="${new_name:-${session_name}-2}"
fi

if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$final_dir"
fi

has_clients=$(tmux list-clients 2>/dev/null)

if [ -n "$TMUX" ] || [ -n "$has_clients" ]; then
    tmux switch-client -t "$session_name"
else
    $terminal -e tmux attach-session -t "$session_name"
fi
