#!/usr/bin/env bash

set -e

# Pega o ID da janela focada e do workspace atual
FOCUSED_JSON=$(niri msg -j focused-window)
FOCUSED_ID=$(echo "$FOCUSED_JSON" | jq -r '.id')
WS_ID=$(echo "$FOCUSED_JSON" | jq -r '.workspace_id')

# Se não houver janela focada, sai
if [ -z "$FOCUSED_ID" ] || [ "$FOCUSED_ID" == "null" ]; then
    exit 0
fi

# Pega todos os IDs das janelas apenas do workspace atual
# A saída do Niri é ordenada da esquerda para a direita
WINDOW_IDS=($(niri msg -j windows | jq -r ".[] | select(.workspace_id == $WS_ID) | .id"))
COUNT=${#WINDOW_IDS[@]}

if [ "$COUNT" -eq 0 ]; then
    exit 0
fi

# Define a porcentagem de acordo com a quantidade
if [ "$COUNT" -eq 1 ]; then
    PCT="100%"
elif [ "$COUNT" -eq 2 ]; then
    PCT="50%"
elif [ "$COUNT" -eq 3 ]; then
    PCT="33.3334%" # Usando 33% para evitar problemas com decimais
else
    PCT="25%" # Piso para 4 ou mais janelas
fi

# Aplica o redimensionamento coluna por coluna
for wid in "${WINDOW_IDS[@]}"; do
    niri msg action focus-window --id "$wid"
    niri msg action set-column-width "$PCT"
done

# Devolve o foco para a janela que você estava usando originalmente
niri msg action focus-window --id "$FOCUSED_ID"
