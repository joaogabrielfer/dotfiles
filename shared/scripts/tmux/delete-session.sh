#!/usr/bin/env bash

current_session=$(tmux display-message -p '#s')
all_sessions=$(tmux list-sessions -F '#S')
if [ -z "$all_sessions" ]; then
    echo "Error: This script must be run from within a tmux session."
    exit 1
fi

kill_session() {
	current_session=$(tmux display-message -p '#s')
	all_sessions=$(tmux list-sessions -F '#S')
	session_to_kill=$(echo "$all_sessions" | fuzzel -d --prompt="Select a session to kill: ")

	if [ -z "$session_to_kill" ]; then
		exit 0
	fi

	if [ "$session_to_kill" == "$current_session" ]; then
		session_count=$(echo "$all_sessions" | wc -l)

		if [ "$session_count" -gt 1 ]; then
			tmux switch-client -n
			tmux kill-session -t "$session_to_kill"
			tmux display-message "Switched away from and deleted session '$session_to_kill'."
		else
			tmux display-message "Deleting last session '$session_to_kill'."
			tmux kill-session -t "$session_to_kill"
		fi
		kill_session
	else
		tmux kill-session -t "$session_to_kill"
		tmux display-message "Session '$session_to_kill' deleted."
		kill_session
	fi
}
kill_session
