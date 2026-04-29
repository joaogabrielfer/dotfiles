#!/usr/bin/env bash

# --- CONFIGURATION ---
VAULT_PATH="$HOME/personal/notas/"  # Path to your Obsidian vault
VAULT_NAME="notas"                  # Exact name of your Obsidian vault
DMENU_CMD="vicinae dmenu"         # Vicinae's dmenu mode (-i for case-insensitivity)
# ---------------------

active_window=$(hyprctl activewindow -j)
initialClass=$(echo "$active_window" | jq -r '.initialClass')

if [[ "$initialClass" == "zen" ]]; then
    # Optional: I left your URL copying logic here but commented it out. 
    # If you want to inject the current page URL into your new note templates, 
    # you can uncomment these and add $URL into the `cat` command below.
    hyprctl dispatch sendshortcut CTRL_SHIFT, C, activewindow
    sleep 0.1
    URL=$(wl-paste)

    # Move the browser to an empty workspace
	hyprctl dispatch workspace 3
    sleep 0.1

    # Prompt with Vicinae for the main action
    MENU_OPTIONS="1. Open existing Obsidian note\n2. Create new note (specify directory)\n3. Create note in brain/notes (with template)"
    CHOICE=$(echo -e "$MENU_OPTIONS" | $DMENU_CMD -p "Obsidian Action:")

    case "$CHOICE" in
        "1. Open existing Obsidian note")
            # Find all .md files, remove ./ prefix and .md extension, pipe to Vicinae
            NOTE=$(cd "$VAULT_PATH" && find . -type f -name "*.md" | sed 's|^\./||' | sed 's|\.md$||' | $DMENU_CMD -p "Select Note:")
            
            if [ -n "$NOTE" ]; then
                # URL-encode the file path (Python is built into Arch) to handle spaces
                ENCODED_NOTE=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$NOTE")
                xdg-open "obsidian://open?vault=$VAULT_NAME&file=$ENCODED_NOTE"
            fi
            ;;
            
        "2. Create new note (specify directory)")
            # Find directories, let user select one
            DIR=$(cd "$VAULT_PATH" && find . -type d | sed 's|^\./||' | $DMENU_CMD -p "Select Directory:")
            
            if [ -n "$DIR" ]; then
                # Pipe an empty string to act as a text input prompt for the file name
                NOTE_NAME=$(echo "" | $DMENU_CMD -p "Note Title:")
                
                if [ -n "$NOTE_NAME" ]; then
                    FILE_PATH="$VAULT_PATH/$DIR/$NOTE_NAME.md"
                    
                    # Create the file
                    touch "$FILE_PATH"
                    
                    # Open in Obsidian
                    ENCODED_FILE=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$DIR/$NOTE_NAME")
                    xdg-open "obsidian://open?vault=$VAULT_NAME&file=$ENCODED_FILE"
                fi
            fi
            ;;
            
        "3. Create note in brain/notes (with template)")
            NOTE_NAME=$(echo "" | $DMENU_CMD -p "Note Title:")
            
            if [ -n "$NOTE_NAME" ]; then
                TARGET_DIR="$VAULT_PATH/brain/notes"
                FILE_PATH="$TARGET_DIR/$NOTE_NAME.md"
                
                # Ensure target directory exists (won't throw an error if it already does)
                mkdir -p "$TARGET_DIR"
                
                # # Write template directly to the file using a Heredoc
                # cat "$VAULT_PATH/templates/template-nota.md" >> "$FILE_PATH"                
                echo "" >> "$FILE_PATH"                
                # Open the newly templated file in Obsidian
                ENCODED_FILE=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "brain/notes/$NOTE_NAME")
                xdg-open "obsidian://open?vault=$VAULT_NAME&file=$ENCODED_FILE"
            fi
            ;;
    esac
	zen-browser --new-window "$URL" &
	sleep 3
	ZEN_ADDRESS=$(hyprctl clients -j | jq -r ".[] | select(.class == \"zen\") | select(.workspace.id == $(hyprctl activeworkspace -j | jq '.id')) | .address")
	hyprctl dispatch sendshortcut CTRL_ALT, C, address:$ZEN_ADDRESS
else
	xdg-open "obsidian://open?vault=$VAULT_NAME"
fi
