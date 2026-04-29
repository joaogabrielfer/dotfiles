#/usr/bin/env bash

# === CONFIGURAÇÃO ===
SINK_NAME="alsa_output.pci-0000_00_1f.3.analog-stereo"
SPEAKERS_PORT="analog-output-headphones"
HEADPHONES_PORT="analog-output-lineout"

# === LÓGICA ===
# Pega a porta ativa atual do seu dispositivo
CURRENT_PORT=$(pactl list sinks | grep 'Active Port' | awk -F': ' '{print $2}' | tr -d ' ')

if [ "$CURRENT_PORT" == "$SPEAKERS_PORT" ]; then
    # 1. Muda para o Fone de Ouvido
    pactl set-sink-port "$SINK_NAME" "$HEADPHONES_PORT"
    
    # 2. Informação visual (Notificação)
    # -h string:x-canonical-private-synchronous:audio faz com que, se você apertar
    # o atalho várias vezes seguidas, a notificação não acumule (spam), ela apenas se atualiza.
    # -t 2000 define o tempo em milissegundos (2 segundos).
    notify-send -h string:x-canonical-private-synchronous:audio \
                -t 2000 \
                "Saída de Áudio" \
                "🎧  <b>Fones de Ouvido</b>"

else
    # 1. Muda para os Alto-falantes
    pactl set-sink-port "$SINK_NAME" "$SPEAKERS_PORT"
    
    # 2. Informação visual (Notificação)
    notify-send -h string:x-canonical-private-synchronous:audio \
                -t 2000 \
                "Saída de Áudio" \
                "🔊  <b>Alto-falantes</b>"
fi
