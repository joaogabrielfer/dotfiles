#!/usr/bin/env python3
import os
import re
import time

# --- CONFIGURATION ---
VAULT_PATH = os.path.expanduser("~/personal/notas")
TASKS_FILES_DIR = os.path.join(VAULT_PATH, "tasks/files")

# This regex looks for:
# 1. A markdown checkbox: - [ ] 
# 2. Text that does NOT contain a [[wikilink]] (so we don't process it twice)
# 3. Contains both #ideia and #to-do anywhere in the line
idea_pattern = re.compile(r'^(\s*- \[[xX ]?\])\s+(?!.*\[\[)(.*?(?:#ideia.*#to-do|#to-do.*#ideia).*)$', re.IGNORECASE)

def process_ideas():
    for root, _, files in os.walk(VAULT_PATH):
        # Optional: If your ideas are only ever in one specific file, you can hardcode that path here to save resources
        for file in files:
            if not file.endswith(".md"): continue
            filepath = os.path.join(root, file)

            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            changed = False
            for i, line in enumerate(lines):
                match = idea_pattern.search(line)
                if match:
                    prefix = match.group(1) # The "- [ ]" part
                    rest_of_line = match.group(2)
                    
                    # Clean the title (remove the tags to get just the idea text)
                    clean_title = rest_of_line.replace('#ideia', '').replace('#to-do', '').strip()
                    # Make it a safe filename
                    safe_title = re.sub(r'[\\/*?:"<>|]', "", clean_title)[:50] 
                    
                    if not safe_title:
                        safe_title = f"Idea_{int(time.time())}"

                    # 1. Create the new Task Note in your tasks folder
                    new_file_path = os.path.join(TASKS_FILES_DIR, f"{safe_title}.md")
                    if not os.path.exists(new_file_path):
                        with open(new_file_path, 'w', encoding='utf-8') as nf:
                            nf.write("---\n")
                            nf.write(f"title: {safe_title}\n")
                            nf.write("status: open\n")
                            nf.write("priority: normal\n")
                            nf.write("due: \n")       # Empty but addable
                            nf.write("scheduled: \n") # Empty but addable
                            nf.write("tags:\n")
                            nf.write("  - task\n")
                            nf.write("---\n\n")
                            nf.write(f"Generated from Idea Backlog.\n\nOriginal thought: {clean_title}\n")

                    # 2. Rewrite the Kanban line to include a link to the new file
                    # This turns "- [ ] cool idea #ideia #to-do" into "- [ ] [[cool idea]] #ideia #to-do"
                    lines[i] = line.replace(clean_title, f"[[{safe_title}]]")
                    changed = True

            # If we modified the file, save it back
            if changed:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                
                # Send a notification to DMS/Wayland so you know it worked!
                os.system(f"notify-send -a 'Obsidian Automator' 'Task Created' '{safe_title}'")

if __name__ == "__main__":
    import time
    
    # Optional: Send a notification when the watcher starts
    os.system("notify-send -u low -a 'Obsidian Automator' 'Watcher Started' 'Listening for new ideas...'")
    
    while True:
        process_ideas()
        time.sleep(120) # Waits 120 seconds (2 minutes) before scanning again
