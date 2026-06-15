#!/usr/bin/env python

import os
import datetime
import subprocess

vault_dir = os.path.expanduser("~/personal/notas/")
today = datetime.datetime.now().strftime("%Y-%m-%d")
tasks_today = []

for root, _, files in os.walk(vault_dir):
    for file in files:
        if file.endswith(".md"):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                content = f.read()
            if content.startswith("---"):
                try:
                    fm = content.split("---")[1]
                except IndexError:
                    continue
                lines = fm.split("\n")
                is_active = False
                is_today = False
                title = file.replace(".md", "")

                for line in lines:
                    if line.startswith("title:"):
                        title = line.replace("title:", "").strip(' "\'')
                    if line.startswith("status:") and "done" not in line.lower():
                        is_active = True
                    if line.startswith("scheduled:") and today in line:
                        is_today = True

                if is_active and is_today:
                    tasks_today.append(title)

if tasks_today:
    body = "\n".join([f"• {t}" for t in tasks_today])
    subprocess.run([
        "notify-send",
        "-a", "Obsidian Tasks",
        "-u", "normal",
        "Tasks for Today",
        body
    ])
else:
    subprocess.run([
        "notify-send",
        "-a", "Obsidian Tasks",
        "No tasks due today."
    ])
