# -------------------------------------------------------------------
# Environment Variables
# -------------------------------------------------------------------
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EDITOR nvim
set -gx MANPAGER "nvim +Man!"
set -gx HYPRSHOT_DIR "$HOME/pictures/screenshots"

if set -q NVIM
    function nvim --wraps nvim --description 'Open files in parent Neovim instance'
        if test (count $argv) -eq 0
            command nvim
            return
        end
        for arg in $argv
            if string match -q -- '-*' $arg; or string match -q -- '+*' $arg
                command nvim $argv
                return
            end
        end
        for file in $argv
            set -l abs (realpath -m -- $file)
            set -l escaped (string replace -a "'" "''" -- $abs)
            command nvim --server "$NVIM" --remote-expr "v:lua.require('config.terminal').open_in_editor('$escaped')" >/dev/null
        end
    end

    function __nvim_send_cmdline
        set -l cur (commandline --cursor)
        set -l cmd (commandline | string collect --no-trim-newlines | string escape --style=url)
        printf '\e]1337;nvim_cmdline=%s;%s;%s\a' "$fish_pid" "$cur" "$cmd" >/dev/tty
    end

    function __nvim_apply_cmdline
        set -l cmdfile "/tmp/nvim-fish-cmd-$fish_pid"
        if not test -f "$cmdfile"
            return
        end
        set -l header ""
        set -l body ""
        begin
            read header
            IFS="" read -z body
        end <"$cmdfile"
        rm -f "$cmdfile"
        set -l parts (string split " " -- "$header")
        set -l exec_flag $parts[1]
        set -l cur_pos $parts[2]
        commandline -r -- "$body"
        if test -n "$cur_pos"
            commandline --cursor -- "$cur_pos"
        end
        set -g fish_bind_mode insert
        commandline -f repaint
        if test "$exec_flag" = "1"
            commandline -f execute
        end
    end

    function __nvim_open_prompt
        __nvim_send_cmdline
        printf '\e]1337;nvim_open_prompt=%s\a' "$fish_pid" >/dev/tty
    end
end

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
set -g fish_transient_prompt 1

function fish_mode_prompt; end

fish_vi_key_bindings

set -g fish_cursor_default block
if set -q NVIM
    set -g fish_cursor_insert line
    set -g fish_cursor_external line
else
    set -g fish_cursor_insert block
end
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

    if set -q NVIM
        bind -M insert ctrl-alt-shift-f11 __nvim_send_cmdline
        bind -M default ctrl-alt-shift-f11 __nvim_send_cmdline
        bind -M insert ctrl-alt-shift-f12 __nvim_apply_cmdline
        bind -M default ctrl-alt-shift-f12 __nvim_apply_cmdline
        bind -M insert alt-e __nvim_open_prompt
        bind -M default alt-e __nvim_open_prompt
        bind -M insert alt-v __nvim_open_prompt
        bind -M default alt-v __nvim_open_prompt
        printf '\e]1337;nvim_fish=%s\a' "$fish_pid" >/dev/tty
    end
end

set -g __fish_git_prompt_color_branch brmagenta -i # -i Sets italics mode
set -g __fish_git_prompt_showcolorhints 1
set -g __fish_git_prompt_showupstream none
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showstashstate 1
set -g __fish_git_prompt_char_cleanstate ''
set -g __fish_git_prompt_color_dirtystate red
set -g __fish_git_prompt_color_stagedstate green
set -g __fish_git_prompt_color_untrackedfiles yellow
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_stashstate cyan
set -e ___fish_git_prompt_init
set -l __git_prompt_cache (set -n | string match -r '^___fish_git_prompt_(color|char)')
if set -q __git_prompt_cache[1]
    set -e $__git_prompt_cache
end

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/joaogabriel/.ghcup/bin $PATH # ghcup-env
