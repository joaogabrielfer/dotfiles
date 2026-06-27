#!/usr/bin/env bash

current_session=$(tmux display-message -p '#S')
all_sessions=$(tmux list-sessions -F '#S')
if [ -z "$all_sessions" ]; then
    echo "Error: This script must be run from within a tmux session."
    exit 1
fi

kill_session() {
	current_session=$(tmux display-message -p '#S')
	all_sessions=$(tmux list-sessions -F '#S')
	session_to_kill=$(echo "$all_sessions" | fuzzel -d --prompt="Select a session to kill: ")

	if [ -z "$session_to_kill" ]; then
		exit 0
	fi

	if [ "$session_to_kill" == "$current_session" ]; then
		switch_to_session=$(echo "$all_sessions" | grep -Fxv -- "$session_to_kill" | head -n 1)

		if [ -n "$switch_to_session" ]; then
			tmux switch-client -t "$switch_to_session"
			tmux kill-session -t "$session_to_kill"
			tmux display-message "Switched to '$switch_to_session' and deleted session '$session_to_kill'."
			kill_session
		else
			tmux display-message "Cannot delete current session '$session_to_kill' because it is the last session."
		fi
		kill_session
	else
		tmux kill-session -t "$session_to_kill"
		tmux display-message "Session '$session_to_kill' deleted."
		kill_session
	fi
}
kill_session
