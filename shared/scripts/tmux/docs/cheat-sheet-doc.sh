#!/usr/bin/env bash

read -p "insira o termo para buscar:
> " input < /dev/tty

if [[ -z "$input" ]]; then
    tmux display-message "No man page selected."
    exit 0
fi

nvim +"term curl -s cheat.sh/$input" -c "nnoremap <buffer> q :q<CR>"
