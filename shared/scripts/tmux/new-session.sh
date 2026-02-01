#!/usr/bin/env bash

PROJECTS_DIR="$HOME/Personal"

if [ ! -d "$PROJECTS_DIR" ]; then
    tmux display-message "Error: Directory '$PROJECTS_DIR' not found."
    exit 1
fi

# 1, 2 e "new project" por último:
# Ordenamos os caminhos, mas deixamos o 'echo' do new project fora do sort
initial_selection_list=$( (
    (
        echo "~"
        echo "~/.config"
        fd . "$PROJECTS_DIR" --min-depth 1 --max-depth 2 --type d | sed "s|^$HOME|~|"
    ) | sort -u
    echo "new project"
) )

selected_display=$(echo "$initial_selection_list" | fzf --prompt="Select Project: " --reverse --no-sort)

if [ -z "$selected_display" ]; then
    exit 0
fi

# Converte o display de volta para caminho real
selected_dir="${selected_display//\~/$HOME}"

# 4. Lógica de Config
if [ "$selected_dir" == "$HOME/.config" ]; then
    final_dir_display=$(fd -td -L -d 1 . "$HOME/.config" | sed "s|^$HOME|~|" | fzf --prompt="Select Config Directory: " --reverse)
    
    if [ -z "$final_dir_display" ]; then
        exit 0
    fi
    final_dir="${final_dir_display//\~/$HOME}"
    subdir=$(basename "$final_dir")
    session_name="config/$subdir"

# 3. Lógica de New Project
elif [[ "$selected_display" == "new project" ]]; then
    prog_dir="$PROJECTS_DIR/Programming"
    
    # Prompt fzf para escolher a pasta dentro de Programming
    category_display=$(fd . "$prog_dir" --max-depth 1 --type d | sed "s|^$HOME|~|" | fzf --prompt="Select Programming Category: " --reverse)
    
    if [ -z "$category_display" ]; then
        exit 0
    fi
    
    category_path="${category_display//\~/$HOME}"
    
    read -p "Insira o nome do projeto: " project_name
    if [ -z "$project_name" ]; then
        echo "No project name provided. Aborting."
        exit 1
    fi

    final_dir="$category_path/$project_name"
    mkdir -p "$final_dir"
    session_name=${project_name#.}

else
    final_dir="$selected_dir"
    session_name_raw=$(basename "$final_dir")
    session_name=${session_name_raw#.}
fi

# 5. Lógica de Sessão Duplicada
if tmux has-session -t "$session_name" 2>/dev/null; then
    # Prompt com o nome padrão já digitado (-i requer Bash 4.0+)
    read -e -p "Sessão '$session_name' já existe. Novo nome: " -i "${session_name}-2" final_session_name
    session_name="${final_session_name:-${session_name}-2}"
fi

# Criação da sessão e switch
if [ -z "$TMUX" ]; then
    tmux new-session -s "$session_name" -c "$final_dir"
    exit 0
fi

tmux new-session -d -s "$session_name" -c "$final_dir"
tmux switch-client -t "$session_name"
