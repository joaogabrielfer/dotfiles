{ config, pkgs, inputs, ... }:

{
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      prompt = "Apps";
      normal_window = true;
      layer = "top";
      term = "ghostty";
      columns = 1;
      width = "25%";
      height = "40%";
      location = 0;
      orientation = "vertical";
      halign = "fill";
      line_wrap = "off";
      dynamic_lines = false;
      allow_markup = true;
      allow_images = true;
      image_size = 24;
      exec_search = false;
      hide_search = false;
      parse_search = false;
      insensitive = true;
      hide_scroll = true;
      no_actions = true;
      sort_order = "default";
      gtk_dark = true;
      filter_rate = 100;
      key_expand = "Tab";
      key_exit = "Ctrl-q";
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
    style = ''
      window {
          margin: 0px;
          border: 2px solid rgba(203, 166, 247, 0.8); /* Mauve Alpha */
          background-color: rgba(30, 30, 46, 0.7);    /* Base Alpha (Transparente) */
          border-radius: 12px;
          font-family: "JetBrainsMono Nerd Font", "monospace";
      }

      #input {
          margin: 10px;
          border: none;
          color: #cdd6f4;
          background-color: rgba(49, 50, 68, 0.8); /* Surface0 */
          border-radius: 8px;
      }

      #inner-box {
          margin: 5px;
          background-color: transparent;
      }

      #outer-box {
          margin: 5px;
          background-color: transparent;
      }

      #text {
          margin: 5px;
          color: #cdd6f4;
      }

      #entry:selected {
          background-color: rgba(69, 71, 90, 0.5); /* Surface1 */
          border-radius: 8px;
      }

      #text:selected {
          color: #fab387; /* Peach */
      }
    '';
  };
}