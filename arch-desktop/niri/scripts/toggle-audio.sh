#!/usr/bin/env bash

# === CONFIGURAÇÃO ===
SINK_NAME="alsa_output.pci-0000_00_1f.3.analog-stereo"
# O nome correto para a saída traseira na maioria das placas é este:
SPEAKERS_PORT="analog-output-lineout"
HEADPHONES_PORT="analog-output-headphones"

# === LÓGICA ===
# Pega a porta ativa EXCLUSIVAMENTE da placa de som correta, ignorando o AudioRelay
CURRENT_PORT=$(pactl -f json list sinks | jq -r ".[] | select(.name == \"$SINK_NAME\") | .active_port")

if [ "$CURRENT_PORT" == "$SPEAKERS_PORT" ]; then
    # 1. Muda para o Fone de Ouvido
    pactl set-sink-port "$SINK_NAME" "$HEADPHONES_PORT"
    
    notify-send -h string:x-canonical-private-synchronous:audio \
                -t 2000 "Saída de Áudio" "🎧  <b>Fones de Ouvido</b>"
else
    # 1. Muda para os Alto-falantes
    pactl set-sink-port "$SINK_NAME" "$SPEAKERS_PORT"
    
    notify-send -h string:x-canonical-private-synchronous:audio \
                -t 2000 "Saída de Áudio" "🔊  <b>Alto-falantes</b>"
fi
