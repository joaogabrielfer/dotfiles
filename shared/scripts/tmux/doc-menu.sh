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
    "man"             m "neww -n man ~/.config/scripts/tmux/docs/man.sh"\
    "go doc"          g "neww -n doc ~/.config/scripts/tmux/docs/go-doc.sh"\
    "cheatsheet"      c "neww -n doc ~/.config/scripts/tmux/docs/cheat-sheet-doc.sh"
