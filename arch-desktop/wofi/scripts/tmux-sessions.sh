#!/usr/bin/env bash

CSS="$HOME/.config/wofi/styles.css"
WOFI_CMD="wofi --dmenu --style $CSS --width 400 --height 300 --prompt 'Mudar para:'"
terminal="alacritty"

sessions=$(tmux list-sessions -F "#S" 2>/dev/null)
[ -z "$sessions" ] && exit 0

selected=$(echo "$sessions" | $WOFI_CMD)
[ -z "$selected" ] && exit 0

# Verifica se existe algum cliente (terminal) ativamente visualizando o tmux
has_clients=$(tmux list-clients 2>/dev/null)

if [ -n "$TMUX" ]; then
    # Caso 1: Rodou de dentro de um terminal com tmux
    tmux switch-client -t "$selected"
elif [ -n "$has_clients" ]; then
    # Caso 2: Rodou via atalho, mas tem um terminal com tmux aberto na tela
    # O switch-client mudará a sessão no terminal que já está visível
    tmux switch-client -t "$selected"
else
    # Caso 3: Não há tmux visível, abre um novo terminal
    $terminal -e tmux attach-session -d -t "$selected"
fi
