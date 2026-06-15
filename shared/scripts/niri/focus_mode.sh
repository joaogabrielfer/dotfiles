#!/usr/bin/env bash

FOCUSED_JSON=$(niri msg -j focused-window)
FOCUSED_ID=$(echo "$FOCUSED_JSON" | jq -r '.id')
WS_ID=$(echo "$FOCUSED_JSON" | jq -r '.workspace_id')

if [ -z "$FOCUSED_ID" ] || [ "$FOCUSED_ID" == "null" ]; then
    exit 0
fi

# Pega as janelas na ordem física atual
WINDOW_IDS=($(niri msg -j windows | jq -r ".[] | select(.workspace_id == $WS_ID) | .id"))
COUNT=${#WINDOW_IDS[@]}

# Descobre a posição (índice) da janela que você está focado
FOCUSED_INDEX=-1
for i in "${!WINDOW_IDS[@]}"; do
    if [ "${WINDOW_IDS[$i]}" == "$FOCUSED_ID" ]; then
        FOCUSED_INDEX=$i
        break
    fi
done

# Altera as larguras: 100% para a focada, 50% para as outras
for wid in "${WINDOW_IDS[@]}"; do
    niri msg action focus-window --id "$wid"
    if [ "$wid" == "$FOCUSED_ID" ]; then
        niri msg action maximize-window-to-edges
    else
        niri msg action set-column-width "50%"
    fi
done

# Restaura o foco para a sua janela principal para poder movê-la
niri msg action focus-window --id "$FOCUSED_ID"

# Lógica da mágica: Se forem 3 janelas, garantir que a principal fique no MEIO
if [ "$COUNT" -eq 3 ]; then
    if [ "$FOCUSED_INDEX" -eq 0 ]; then
        # Se estava na ponta ESQUERDA, move uma vez para a direita
        niri msg action move-column-right
    elif [ "$FOCUSED_INDEX" -eq 1 ]; then
        # Se estava na ponta DIREITA, move uma vez para a esquerda
        niri msg action move-column-left
    fi
fi
