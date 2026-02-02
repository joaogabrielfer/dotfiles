#!/usr/bin/env bash

PROJECTS_DIR="$HOME/Personal"
# Configuração base do Wofi
CSS="$HOME/.config/wofi/styles.css"
WOFI_BASE="wofi --dmenu --style $CSS --width 60% --height 50% -w 2 --prompt 'Mudar para:'"
terminal="alacritty"

# Função para pedir texto via Wofi (substitui o read -p)
wofi_input() {
    wofi --dmenu --width 400 --height 50 --style $CSS --prompt "$1" --cache-file /dev/null
}

# 1. Gerar lista inicial
initial_list=$( (
    (
        echo "home"
        echo "~/.config"
        fd . "$PROJECTS_DIR" --min-depth 1 --max-depth 2 --type d | sed "s|^$HOME|~|"
    ) | sort -u
    echo "new project"
) )

selected_display=$(echo "$initial_list" | $WOFI_BASE --prompt "Selecionar Projeto:")
[ -z "$selected_display" ] && exit 0

# Lógica para converter o nome de exibição para o caminho real
if [ "$selected_display" == "home" ]; then
    selected_dir="$HOME"
else
    selected_dir="${selected_display//\~/$HOME}"
fi

# Lógica de Config
if [ "$selected_dir" == "$HOME/.config" ]; then
    # Gera lista combinando .config, ~/dotfiles, e subpastas de arch-desktop e shared
    dirs=$( (
        echo "dotfiles"
        fd . -td -tl "$HOME/.config" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/arch-desktop" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/shared" --max-depth 1 --exec echo {/}
    ) | sed 's/\/$//' | sort -u )

    final_display_dir=$(echo "$dirs" | $WOFI_BASE --prompt "Pasta de Config:")
    [ -z "$final_display_dir" ] && exit 0
    
    # Define o caminho real baseado em onde a pasta foi encontrada (precedência: .config > arch-desktop > shared)
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

# Lógica de New Project
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

else
    final_dir="$selected_dir"
    session_name=$(basename "$final_dir" | sed 's/^\.//')
fi

# Lógica de Sessão Duplicada (Usa Wofi para perguntar novo nome)
if tmux has-session -t "$session_name" 2>/dev/null; then
    new_name=$(echo "${session_name}-2" | wofi_input "Sessão já existe! Novo nome:")
    session_name="${new_name:-${session_name}-2}"
fi

# Abre no Terminal
if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$final_dir"
fi

# 2. Verifica se existe algum terminal com tmux ativamente aberto
has_clients=$(tmux list-clients 2>/dev/null)

if [ -n "$TMUX" ] || [ -n "$has_clients" ]; then
    tmux switch-client -t "$session_name"
else
    $terminal -e tmux attach-session -t "$session_name"
fi
