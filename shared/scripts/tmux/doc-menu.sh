#! /usr/bin/env bash

# Color definitions
text="#e6d9d4"
blue="#a9d4ff"
peach="#da9367"

tmux menu \
    -T "#[fg=${blue},bold] menu " \
    -b rounded \
    -s "fg=${text}" \
    -S "fg=${peach}" \
    -H "fg=${text}" \
    "man"             m "neww -n man ~/.config/scripts/tmux/legacy/man.sh"\
    "go doc"          g "neww -n man ~/.config/scripts/tmux/legacy/go-doc.sh"
