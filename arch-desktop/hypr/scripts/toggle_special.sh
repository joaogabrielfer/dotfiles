#!/bin/bash

# Get the ID of the currently active workspace
ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r ".id")

if [ "$ACTIVE_WORKSPACE" -eq 11 ]; then
    # If we are on workspace 10, go back to the previous one
    hyprctl dispatch workspace previous
else
    # If we are on any other workspace, go to workspace 10
    hyprctl dispatch workspace 11
fi

pkill -RTMIN+8 waybar
