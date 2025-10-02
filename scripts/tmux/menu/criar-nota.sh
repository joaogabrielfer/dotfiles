#!/usr/bin/env bash

NOTES_DIR="$HOME/Personal/Notas"
EDITOR=${EDITOR:-nvim}


mkdir -p "$NOTES_DIR"

read -p "Insira o nome da nota: " note_name

if [ -z "$note_name" ]; then
    echo "No note name provided. Aborting."
    exit 1
fi

full_path="$NOTES_DIR/$note_name.md"

note_dir=$(dirname "$full_path")

mkdir -p "$note_dir"
exec "$EDITOR" "$full_path"
