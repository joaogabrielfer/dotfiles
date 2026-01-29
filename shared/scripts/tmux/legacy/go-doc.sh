#!/bin/bash

packages=$((go list ... 2>/dev/null; go list all 2>/dev/null) | sort -u)

selected_package=$(echo "$packages" | fzf --prompt="Select a Go package: ")

if [ -z "$selected_package" ]; then
    exit 0
fi

symbol_lines=$(go doc -short "$selected_package" | grep -E '^(func|type|var|const) ')

selected_line=$(echo "$symbol_lines" | fzf --prompt="Select a symbol (or press Enter for package doc): ")

doc_args=("$selected_package")

if [ -n "$selected_line" ]; then
    selected_symbol=$(echo "$selected_line" | awk '
        {
            if ($1 == "func" && $2 ~ /^\(/) { # It is a method: func (receiver) Name(...)
                symbol = $3
            } else { # It is a func, type, var, or const
                symbol = $2
            }
            # Strip trailing characters like parentheses or brackets
            sub(/\(.*/, "", symbol)
            sub(/\[.*/, "", symbol)
            print symbol
        }
    ')
    doc_args+=("$selected_symbol")
fi

go doc "${doc_args[@]}" | nvim -R -c 'set ft=go buftype=nofile | nnoremap <buffer> q :q<CR>' 
