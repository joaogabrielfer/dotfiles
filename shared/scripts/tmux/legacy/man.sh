#!/usr/bin/env bash

SELECTED=$(apropos . | sed -r 's/\).*/)/g' | fzf --reverse)

if [[ -z "$SELECTED" ]]; then
    tmux display-message "No man page selected."
    exit 0
fi

MAN_ARGS=$(echo "$SELECTED" | sed -E 's/^([a-zA-Z._-]+) \(([0-9a-zA-Z]+)\)$/\2 \1/')

# --- THE FINAL POLISH ---
# We chain multiple commands to nvim to make it behave perfectly.
#
# 1. `set ft=man`: Enables syntax highlighting.
#
# 2. `set buftype=nofile`: This is the key. It tells nvim that this buffer
#    is not associated with a file on disk. As a result, nvim will not
#    prompt you to save it when you try to quit.
#
# 3. `nnoremap <buffer> q :q<CR>`: This creates a keyboard mapping. It makes
#    pressing the `q` key in normal mode execute the `:q` command, exactly
#    like the `less` pager and other man page viewers. The `<buffer>` argument
#    is important, ensuring this mapping only applies to this specific
#    man page buffer and not globally to your entire nvim session.

exec man -P cat $MAN_ARGS | col -b | nvim -c 'set ft=man | set buftype=nofile | nnoremap <buffer> q :q<CR>' -
