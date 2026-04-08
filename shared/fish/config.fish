# -------------------------------------------------------------------
# Environment Variables
# -------------------------------------------------------------------
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EDITOR nvim
set -gx MANPAGER "nvim +Man!"
set -gx HYPRSHOT_DIR "$HOME/Pictures/screenshots"

# -------------------------------------------------------------------
# Path
# -------------------------------------------------------------------
fish_add_path $HOME/go/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin

# -------------------------------------------------------------------
# Aliases
# -------------------------------------------------------------------
alias ls 'eza --icons --header'
alias la 'eza --icons --header -long -A'
alias tns 'tmux new-session -n session "/home/joaogabriel/.config/scripts/tmux/new-session.sh"'
alias ta 'tmux a'
alias edit 'sudo -e'

alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

alias gacp 'git add .; and git commit; and git push origin main'
alias gl "git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# -------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------

set -g fish_greeting

function fish_mode_prompt; end

fish_vi_key_bindings

set -g fish_cursor_default block
set -g fish_cursor_insert block
set -g fish_cursor_replace_one underscore
set -g fish_cursor_visual block

bind -M insert \cf forward-char

set -g __fish_git_prompt_color_branch brmagenta -i # -i Sets italics mode
set -g __fish_git_prompt_showupstream none
