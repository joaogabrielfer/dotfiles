#!/usr/bin/env bash

PERSONAL_DIR="$HOME/personal"
PROGRAMMING_DIR="$HOME/personal/programming/"
# Adicionado diretório de notas
NOTES_DIR="$HOME/personal/notas"

LAUNCHER="fuzzel --dmenu --width 35% --lines 15 --prompt 'Mudar para:'"
terminal="alacritty"

launcher_input() {
    fuzzel --dmenu --width 40 --lines 2 --prompt "$1"
}

initial_list=$( (
    (
        echo "home"
        echo "config"
        echo "personal"
        echo "programming"
        echo "notas"
    ) ) )

selected_display=$(echo "$initial_list" | $LAUNCHER --prompt "Selecionar Projeto:")
[ -z "$selected_display" ] && exit 0

if [ "$selected_display" == "home" ]; then
    selected_dir="$HOME"
else
    selected_dir="${selected_display//\~/$HOME}"
fi

# Variável para comando específico (ex: nvim arquivo)
custom_command=""

if [ "$selected_dir" == "config" ]; then
    dirs=$( (
        echo "dotfiles"
        fd . -td -tl "$HOME/.config" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/arch-desktop" --max-depth 1 --exec echo {/}
        fd . -td -tl "$HOME/dotfiles/shared" --max-depth 1 --exec echo {/}
    ) | sed 's/\/$//' | sort -u )

    final_display_dir=$(echo "$dirs" | $LAUNCHER --prompt "Pasta de Config:")
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

# ---------------------------------------------------------
# LÓGICA DE NOTAS (ADICIONADA)
# ---------------------------------------------------------
elif [[ "$selected_dir" == "notas" ]]; then
    selection=$( (
        echo "nova"
        fd --type f . "$NOTES_DIR" | sed "s|^$NOTES_DIR/||"
    ) | $LAUNCHER --prompt "Nota:")

    [ -z "$selection" ] && exit 0

    if [[ "$selection" == "nova" ]]; then
        note_name=$(echo "" | launcher_input "Nome da nota (sem .md):")
        [ -z "$note_name" ] && exit 1
        
        filename="${note_name}.md"
        # Cria diretório pai se necessário
        mkdir -p "$(dirname "$NOTES_DIR/$filename")"
    else
        filename="$selection"
    fi

    final_dir="$NOTES_DIR"
    
    # Sanitiza o nome para a sessão do tmux (remove .md e troca / por _)
    sanitized_name=$(echo "$filename" | sed 's/\.md$//')
    session_name="notas"
    
    # Define o comando para abrir o nvim direto no arquivo
	custom_command="nvim '$filename'"

elif [[ "$selected_dir" == "programming" ]]; then
    selection=$((
        echo "new-project"
        fd . -td -tl "$PROGRAMMING_DIR" --min-depth 2 --max-depth 2
        echo "tmp"
        ) | sed -E 's/^\/.*(\/.*\/.*\/)/\1/' | sed -E 's/^\/(.*)\/$/\1/' | sed -E 's/^tmp\/.*$//' | sed '/^[[:blank:]]*$/d' | $LAUNCHER --prompt "Projeto:")

    [ -z "$selection" ] && exit 0

    if [[ "$selection" == "new-project" ]]; then
        category_display=$((
            fd . "$PROGRAMMING_DIR" --max-depth 1 --type d 
            ) | sed -E 's/^\/.*(\/.*\/.*\/)/\1/' | sed -E 's/^\/(.*)\/$/\1/' | sed -E 's/.*\/tmp//' | sed '/^[[:blank:]]*$/d' | $LAUNCHER --prompt "Categoria:")
        [ -z "$category_display" ] && exit 0
        
        category_path="$PERSONAL_DIR/$category_display"
		echo aqui
        project_name=$(echo "" | launcher_input "Nome do novo projeto:")
        [ -z "$project_name" ] && exit 1

        final_dir="$category_path/$project_name"
        mkdir -p "$final_dir"
        session_name="$(basename $category_display)/$project_name"
    else
        final_dir="$PROGRAMMING_DIR$selection"
        mkdir -p "$final_dir"
        session_name=$selection
    fi
elif [[ "$selected_dir" == "personal" ]]; then
    selection=$((
        fd . -td -tl "$PERSONAL_DIR" --max-depth 2
        ) | sed -E 's/^\/.*(\/.*\/.*\/)/\1/' | sed -E 's/^\/(.*)\/$/\1/' | sed -E 's/^.*programming.*//' | sed '/^[[:blank:]]*$/d' | $LAUNCHER --prompt "Projeto:")

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

# Tratamento de sessão duplicada
if tmux has-session -t "$session_name" 2>/dev/null; then
    # Se já existe, pergunta novo nome, mas mantém o custom_command (se houver)
    new_name=$(echo "${session_name}-2" | launcher_input "Sessão já existe! Novo nome:")
    session_name="${new_name:-${session_name}-2}"
fi

if ! tmux has-session -t "$session_name" 2>/dev/null; then
	if [[ "$selected_dir" == "notas" ]]; then
		tmux new-session -d -s "$session_name" -c "$final_dir" "$custom_command"
	else 
		tmux new-session -d -s "$session_name" -c "$final_dir"
	fi
fi

has_clients=$(tmux list-clients 2>/dev/null)

if [ -n "$TMUX" ] || [ -n "$has_clients" ]; then
    tmux switch-client -t "$session_name"
else
    $terminal -e tmux attach-session -t "$session_name"
fi
