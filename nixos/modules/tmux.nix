{ config, pkgs, inputs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "alacritty";
    escapeTime = 0;
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      catppuccin
    ];
    extraConfig = ''
      # -------------------------------------------------------------------
      # Core Settings & Plugins
      # -------------------------------------------------------------------
      set -as terminal-overrides ",alacritty:Tc"
      set-option -g allow-passthrough on
      set-option -g default-shell ${pkgs.fish}/bin/fish

      set -g @catppuccin_flavor "mocha"

      # -------------------------------------------------------------------
      # Keybindings
      # -------------------------------------------------------------------
      unbind C-b
      set-option -g prefix C-a
      bind-key C-a send-prefix
      set -g renumber-windows on

      bind r source-file ~/.config/tmux/tmux.conf
      bind q kill-window
      bind & display-panes
      bind c neww -c "~"

      set-window-option -g mode-keys vi
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

      bind -r ^ last-window
      bind -rn M-h select-pane -L
      bind -rn M-j select-pane -D
      bind -rn M-k select-pane -U
      bind -rn M-l select-pane -R

      bind -r H resize-pane -L 2
      bind -r J resize-pane -D 2
      bind -r K resize-pane -U 2
      bind -r L resize-pane -R 2

      bind-key -n M-1 select-window -t :=1
      bind-key -n M-2 select-window -t :=2
      bind-key -n M-3 select-window -t :=3
      bind-key -n M-4 select-window -t :=4
      bind-key -n M-5 select-window -t :=5
      bind-key -n M-6 select-window -t :=6
      bind-key -n M-7 select-window -t :=7
      bind-key -n M-8 select-window -t :=8
      bind-key -n M-9 select-window -t :=10

      bind-key -n M-! swap-window -d -t 1
      bind-key -n M-@ swap-window -d -t 2
      bind-key -n M-# swap-window -d -t 3
      bind-key -n M-$ swap-window -d -t 4
      bind-key -n M-% swap-window -d -t 5
      bind-key -n M-^ swap-window -d -t 6
      bind-key -n M-& swap-window -d -t 7
      bind-key -n M-* swap-window -d -t 8
      bind-key -n M-( swap-window -d -t 9

      bind-key "S" neww "$HOME/.config/scripts/tmux/launcher.sh"
      bind-key "m" neww -n session "$HOME/.config/scripts/tmux/doc-menu.sh"
      bind-key "R" neww -n session "$HOME/.config/scripts/tmux/delete-session.sh"
      bind-key "F" neww -c "#{pane_current_path}"

      # -------------------------------------------------------------------
      # Styling
      # -------------------------------------------------------------------
      set-option -g status-position bottom
      set -g status-style "bg=default"
      set -g status-justify "absolute-centre"

      # Left side of status bar (white)
      set -g status-left-length 100
      set -g status-left ""
      set -ga status-left "#[bg=default,fg=#{@thm_text}]  #{pane_current_command} "
      set -ga status-left "#[bg=default,fg=#{@thm_text},none]│"
      set -ga status-left "#[bg=default,fg=#{@thm_text}]  #{=/-32/...:#{s|$USER|~|:#{b:pane_current_path}}} "
      set -ga status-left "#[bg=default,fg=#{@thm_text},none]#{?window_zoomed_flag,│,}"
      set -ga status-left "#[bg=default,fg=#{@thm_text}]#{?window_zoomed_flag,  zoom ,}"

      # Right side of status bar (white)
      set -g status-right-length 100
      set -g status-right ""
      set -ga status-right "#[bg=default,fg=#{@thm_text},none]│"
      set -ga status-right "#{?client_prefix,#{#[bg=#{@thm_red},fg=#{@thm_bg},bold]  #S },#{#[bg=default,fg=#{@thm_text}]  #S }}"

      # Window naming behavior
      set -wg automatic-rename on

      # Inactive window style (white)
      set -g window-status-format " #I:#W "
      set -g window-status-style "bg=default,fg=#{@thm_text}"
      set -gF window-status-separator "#[bg=default,fg=#{@thm_text}]│"

      # Active window style (colored)
      set -g window-status-current-format " #I:#W "
      set -g window-status-current-style "bg=default,fg=#{@thm_peach},bold"

      # Pane border styles
      setw -g pane-active-border-style "fg=#{@thm_peach}"
      setw -g pane-border-style "fg=#{@thm_text}"
      setw -g pane-border-lines single
      setw -g pane-border-status bottom
      setw -g pane-border-format ""
    '';
  };

  xdg.configFile."scripts/tmux/launcher.sh".text = builtins.replaceStrings 
    [ "/home/joaogabriel" ] 
    [ config.home.homeDirectory ] 
    (builtins.readFile (inputs.my-dotfiles + "/shared/tmux/launcher.sh"));
}