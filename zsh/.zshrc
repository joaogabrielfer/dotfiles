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
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export HISTSIZE=268435456
export SAVEHIST="$HISTSIZE"
export HISTFILE="$ZDOTDIR/.zsh_history"
setopt INC_APPEND_HISTORY

export HYPRSHOT_DIR="$HOME/Pictures/screenshots"
export MANPAGER="nvim +Man!"
export EDITOR="nvim"


 nvim() {
    if [ "$#" -eq 1 ] && [ -d "$1" ] && [ "$1" != "." ]; then
	pushd $1
	command nvim .
	popd
    elif [ "$#" -eq 1 ] && [ "$1" = "." ]; then
	command nvim $1
    elif [ "$#" -eq 0 ]; then
	echo "teste"
	command nvim . 
    else
	pushd $(dirname "$1")
	command nvim $(basename "$1")
	popd 
    fi
}

alias ls='ls --color=auto'
alias la='ls -lha --color=auto'
alias szsh='source ~/.config/zsh/.zshrc'
