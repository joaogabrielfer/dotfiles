# -------------------------------------------------------------------
# Environment Variables
# -------------------------------------------------------------------
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EDITOR nvim
set -gx MANPAGER "nvim +Man!"
set -gx HYPRSHOT_DIR "$HOME/pictures/screenshots"

# -------------------------------------------------------------------
# Path
# -------------------------------------------------------------------
fish_add_path $HOME/go/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin

set -gx --path XDG_DATA_DIRS $XDG_DATA_DIRS

# Append Flatpak share directories if they aren't already present
for flatpak_dir in ~/.local/share/flatpak/exports/share /var/lib/flatpak/exports/share
    if test -d $flatpak_dir
        and not contains $flatpak_dir $XDG_DATA_DIRS
        set -ga XDG_DATA_DIRS $flatpak_dir
    end
end

# sourcing files
source ~/.config/fish/completions/dms_completion.fish

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

if status is-interactive
    # Disable fzf's default Ctrl-T binding before loading integration
    set -gx FZF_CTRL_T_COMMAND ''

    fzf --fish | source

    # File path picker: Ctrl-x Ctrl-F
	bind \cx\cf fzf-file-widget
	bind -M insert \cx\cf fzf-file-widget

    set -gx FZF_DEFAULT_OPTS "
        --height 40%
        --layout=reverse
        --border
    "

    set -gx FZF_CTRL_T_OPTS "
        --preview 'bat --style=numbers --color=always {} 2>/dev/null || eza -la --color=always {} 2>/dev/null'
    "

    set -gx FZF_ALT_C_OPTS "
        --preview 'eza -la --color=always {} 2>/dev/null'
    "
end

set -g __fish_git_prompt_color_branch brmagenta -i # -i Sets italics mode
set -g __fish_git_prompt_showupstream none

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/joaogabriel/.ghcup/bin $PATH # ghcup-env
