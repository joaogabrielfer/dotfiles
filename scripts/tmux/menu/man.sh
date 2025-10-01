#!/usr/bin/env bash

# tmux neww -n man "apropos . | sed -r 's/\(.*//g' | fzf | xargs man"

SELECTED=$(apropos . | sed -r 's/\).*/)/g' | fzf)

if [[ -z "$SELECTED" ]]; then
    echo "No selection made."
    exit 0
fi

man $( echo "$SELECTED" | sed -E 's/^([a-zA-Z]+) \(([0-9])\)$/\2 \1/')

