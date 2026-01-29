#!/usr/bin/env bash

sessions=$(tmux list-sessions -F '#S' | sort)

if [ -z "$sessions" ]; then
    exit 0
fi

selected_session=$(echo "$sessions" | fzf --reverse)

if [ -z "$selected_session" ]; then
    exit 0
fi

tmux switch-client -t "$selected_session"
