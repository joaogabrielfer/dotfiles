ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit snippet OMZL::history.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::key-bindings.zsh

zinit wait lucid for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  zdharma-continuum/history-search-multi-word

autoload -U colors && colors
PS1="%{$fg[white]%}[%{$reset_color%}%{$fg[red]%}%1~%{$reset_color%}%{$fg[white]%}]%{$reset_color%}%{$fg[green]%}$ %{$reset_color%}%"

export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR=$HOME/

export HISTSIZE=268435456
export HISTFILE=$HOME/.zsh_history
export SAVEHIST="$HISTSIZE"
setopt INC_APPEND_HISTORY

export HYPRSHOT_DIR="$HOME/Pictures/screenshots"
export MANPAGER="nvim +Man!"
export EDITOR="nvim"

export PATH=$PATH:$HOME/go/bin

alias ls='eza --icons --header'
alias la='eza --icons --header -long -A'

alias tns='tmux new-session -n session  "/home/joaogabriel/.config/scripts/tmux/new-session.sh"'
alias ta='tmux a'

function lt(){
	if [[ "$#" -gt 1 ]]; then
		eza --icons --header -long -A -T --level=$2 $1
	else
		eza --icons --header -long -A -T --level=2 $1
	fi
}

alias szsh='source /home/joaogabriel/.zshrc'

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
