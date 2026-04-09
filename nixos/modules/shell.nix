{ config, pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;
    shellInit = ''
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
    '';
    shellAliases = {
      ls = "eza --icons --header";
      la = "eza --icons --header -long -A";
      tns = "tmux new-session -n session \"$HOME/.config/scripts/tmux/new-session.sh\"";
      ta = "tmux a";
      edit = "sudo -e";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      gacp = "git add .; and git commit; and git push origin main";
      gl = "git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  # Map fish functions and variables
  xdg.configFile."fish/functions".source = "${inputs.my-dotfiles}/shared/fish/functions";
  xdg.configFile."fish/conf.d".source = "${inputs.my-dotfiles}/shared/fish/conf.d";

  programs.zsh = {
    enable = true;
    initExtra = ''
      ZINIT_HOME="''${XDG_DATA_HOME:-''${HOME}/.local/share}/zinit/zinit.git"

      [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
      [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
      source "''${ZINIT_HOME}/zinit.zsh"

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

      function lt(){
        if [[ "$#" -gt 1 ]]; then
          eza --icons --header -long -A -T --level=$2 $1
        else
          eza --icons --header -long -A -T --level=2 $1
        fi
      }
    '';
    envExtra = ''
      export XDG_CONFIG_HOME="$HOME/.config"

      export HISTSIZE=268435456
      export HISTFILE=$HOME/.zsh_history
      export SAVEHIST="$HISTSIZE"
      setopt INC_APPEND_HISTORY

      export HYPRSHOT_DIR="$HOME/Pictures/screenshots"
      export MANPAGER="nvim +Man!"
      export EDITOR="nvim"

      export PATH=$PATH:$HOME/go/bin
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$PATH:$HOME/.local/bin"
    '';
    shellAliases = {
      ls = "eza --icons --header";
      la = "eza --icons --header -long -A";
      tns = "tmux new-session -n session  \"$HOME/.config/scripts/tmux/new-session.sh\"";
      ta = "tmux a";
      edit = "sudo -e";
      szsh = "source $HOME/.zshrc";
      "~" = "cd ~";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      gacp = "git add . && git commit && git push origin main";
      gl = "git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  # Scripts mapping
  xdg.configFile."scripts".source = "${inputs.my-dotfiles}/shared/scripts";
}