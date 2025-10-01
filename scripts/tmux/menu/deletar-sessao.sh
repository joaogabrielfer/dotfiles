#!/usr/bin/env bash

current_session=$(tmux display-message -p '#S')

sessions_to_delete=$(tmux list-sessions -F '#S' | grep -v "^$current_session$")

if [ -z "$sessions_to_delete" ]; then
    tmux display-message "No other sessions to delete."
    exit 0
fi

session_to_kill=$(echo "$sessions_to_delete" | fzf --reverse)

if [ -z "$session_to_kill" ]; then
    exit 0
fi

tmux kill-session -t "$session_to_kill"
tmux display-message "Session '$session_to_kill' deleted."
