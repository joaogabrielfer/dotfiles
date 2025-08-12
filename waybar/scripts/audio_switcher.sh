#!/bin/bash

# --- CONFIGURATION ---
# The name of your single audio device (sink)
SINK_NAME="alsa_output.pci-0000_00_1f.3.analog-stereo"

# The names of your two ports, confirmed from your output
SPEAKERS_PORT="analog-output-lineout"
HEADPHONES_PORT="analog-output-headphones"

# --- SCRIPT LOGIC ---
# Get the name of the currently active port
CURRENT_PORT=$(pactl list sinks | grep 'Active Port' | awk -F': ' '{print $2}')

# Function to switch the active port
switch_port() {
    if [ "$CURRENT_PORT" == "$SPEAKERS_PORT" ]; then
        pactl set-sink-port "$SINK_NAME" "$HEADPHONES_PORT"
    else
        pactl set-sink-port "$SINK_NAME" "$SPEAKERS_PORT"
    fi
}

# Function to output JSON for Waybar's display
update_display() {
    if [ "$CURRENT_PORT" == "$SPEAKERS_PORT" ]; then
        echo '{"text":"", "tooltip":"Output: Speakers"}'
    else
        echo '{"text":"", "tooltip":"Output: Headphones"}'
    fi
}

# Main logic: if the argument is "switch", run the switch function.
# Otherwise, just run the display function.
if [ "$1" == "switch" ]; then
    switch_port
else
    update_display
fi
