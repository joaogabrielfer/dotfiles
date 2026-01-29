#!/usr/bin/env bash

# --- Configuration ---
PROJECTS_DIR="$HOME/Personal"

# --- Data Gathering ---
if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Error: Directory '$PROJECTS_DIR' not found."
    exit 1
fi

# Get a list of active tmux session names.
if tmux has-session 2>/dev/null; then
    active_sessions=$(tmux list-sessions -F '#S' | sort)
else
    active_sessions=""
fi

# Gather all potential project directory paths.
all_dir_paths=$(cat <<EOF
$HOME
$HOME/.config
$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 2 -type d)
EOF
)

# --- Filtering Logic ---
# Filter out directories that correspond to an already active session.
available_dirs=""
for path in $all_dir_paths; do
    # Determine the session name that *would* be created for this path.
    session_name_for_path=""
    if [[ "$path" == "$HOME" ]]; then
        session_name_for_path="home"
    elif [[ "$path" == "$HOME/.config" ]]; then
        session_name_for_path="config"
    else
        session_name_for_path=$(basename "$path")
    fi

    # Check if this name already exists in the list of active sessions.
    if ! echo "$active_sessions" | grep -q -x "$session_name_for_path"; then
        available_dirs+="$path\n"
    fi
done
# Remove the final trailing newline if it exists.
available_dirs=$(echo -e "${available_dirs}" | sed '/^$/d')


# --- FZF Selection Loop ---
# Loop indefinitely until a valid choice is made or the user cancels.
while true; do
    # --- FZF Input Preparation ---
    fzf_input=$(
        # Category 1: Active Sessions
        if [ -n "$active_sessions" ]; then
            echo "╭─ Active Sessions ───────"
            echo "$active_sessions"
            echo ""
        fi

        # Category 2: Directories (Available Projects)
        if [ -n "$available_dirs" ]; then
            echo "╭─ Available Projects ─────"
            echo "$available_dirs" | sed "s|^$HOME/|~/|" | sed "s|^$HOME$|home|"
        fi

        # Category 3: Other
        echo ""
        echo "╭─ Other ──────────────────"
        echo "outro:"
    )

    selected_choice=$(echo "$fzf_input" | fzf --reverse)

    # Exit if the user cancelled (pressed Esc).
    if [ -z "$selected_choice" ]; then
        exit 0
    fi

    # --- GUARDRAIL ---
    # Check if the user selected a header. The '*' is a wildcard.
    if [[ "$selected_choice" == "╭─"* ]]; then
        # Invalid selection. The loop will `continue` and re-prompt.
        continue
    else
        # Valid selection, break the loop and proceed.
        break
    fi
done

# --- Post-Selection Processing ---
# This code is only reached after a valid selection is made.
session_name=""
selected_dir=""

# Case 1: The user selected the "outro:" option.
if [[ "$selected_choice" == "outro:" ]]; then
    read -p "Enter new session name: " session_name < /dev/tty
    if [ -z "$session_name" ]; then exit 0; fi
    selected_dir="$HOME"

# Case 2: The choice is an active session name.
elif echo "$active_sessions" | grep -q -x "$selected_choice"; then
    session_name="$selected_choice"

# Case 3: The choice is a directory.
else
    # Reverse the display formatting to get the real path.
    if [[ "$selected_choice" == "home" ]]; then
        selected_dir="$HOME"
        session_name="home"
    else
        selected_dir=${selected_choice/#\~/$HOME}
        if [[ "$selected_dir" == "$HOME/.config" ]]; then
            session_name="config"
        else
            session_name=$(basename "$selected_dir")
        fi
    fi
fi

# --- TMUX Execution ---
# Attach to the session if it already exists.
if tmux has-session -t "$session_name" 2>/dev/null; then
    exec tmux attach-session -t "$session_name"
else
    # Create a new session.
    exec tmux new-session -s "$session_name" -c "${selected_dir:-$HOME}"
fi
