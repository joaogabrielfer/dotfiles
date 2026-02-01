#!/bin/bash
# Verifica se o workspace 11 está focado no Hyprland
ACTIVE_WS=$(hyprctl activeworkspace -j | jq '.id')

if [ "$ACTIVE_WS" == "11" ]; then
    # Retorna JSON com a classe "active"
    echo '{"text": "", "class": "active"}'
else
    # Retorna JSON sem classe especial
    echo '{"text": "", "class": "inactive"}'
fi
