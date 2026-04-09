{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    style = ''
      @define-color rosewater #f5e0dc;
      @define-color flamingo #f2cdcd;
      @define-color pink #f5c2e7;
      @define-color mauve #cba6f7;
      @define-color red #f38ba8;
      @define-color maroon #eba0ac;
      @define-color peach #fab387;
      @define-color yellow #f9e2af;
      @define-color green #a6e3a1;
      @define-color teal #94e2d5;
      @define-color sky #89dceb;
      @define-color sapphire #74c7ec;
      @define-color blue #89b4fa;
      @define-color lavender #b4befe;
      @define-color text #cdd6f4;
      @define-color subtext1 #bac2de;
      @define-color subtext0 #a6adc8;
      @define-color overlay2 #9399b2;
      @define-color overlay1 #7f849c;
      @define-color overlay0 #6c7086;
      @define-color surface2 #585b70;
      @define-color surface1 #45475a;
      @define-color surface0 #313244;
      @define-color base #1e1e2e;
      @define-color mantle #181825;
      @define-color crust #11111b;

      * {
          font-family: "SF Pro Text", "JetBrains Mono Light", "Geist Mono", "MesloLGS NF";
          font-size: 13px;
          font-weight: 400;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background-color: rgba(17, 17, 27, 0.7);
          color: @text;
          border-bottom: 1px solid rgba(250, 179, 135, 0.2);
      }

      /* ───────────── SEPARADOR ───────────── */
      #custom-sep {
          color: @surface2;
          padding: 0 12px;
          font-size: 16px;
      }

      /* ───────────── WORKSPACES ───────────── */

      /* base */
      #workspaces button {
          padding: 0 8px;
          color: @subtext0;
          transition: all 0.2s ease;
        border-radius: 10%;
      }

      /* vazio */
      #workspaces button.empty {
          color: rgba(69, 71, 90, 0.45);
      }

      /* 2️⃣ OCUPADO / INATIVO */
      #workspaces button:not(.active):not(.persistent) {
          color: @subtext0;
      }

      /* ativo */
      #workspaces button.active {
          color: @peach;
          background-color: rgba(250, 179, 135, 0.15);
          border-bottom: 2px solid @peach;
        padding: 0px 10px;
      }

      /* Home (workspace 11) nunca some totalmente */
      #workspaces-home button.persistent {
          color: rgba(250, 179, 135, 0.35);
      }

      /* ───────────── JANELA ───────────── */
      #window {
          color: @subtext1;
          margin-left: 10px;
      }

      /* ───────────── MÓDULOS DIREITA ───────────── */
      #network,
      #pulseaudio,
      #custom-audio-switcher,
      #clock,
      #cpu,
      #memory,
      #custom-power {
          padding: 0 12px;
          margin: 5px 3px;
          border-radius: 8px;
          background-color: rgba(205, 214, 244, 0.05);
      }

      #network,
      #custom-audio-switcher,
      #clock {
          color: @peach;
      }

      #pulseaudio {
          color: @maroon;
      }

      #custom-audio-switcher{
        padding-right: 20px;
      }

      #custom-power {
          color: @red;
          background-color: rgba(243, 139, 168, 0.1);
          font-size: 15px;
          margin-right: 10px;
        padding-right: 15px;
      }

      #custom-home {
        margin-left: 15px;
        margin-right: 0px;

        padding: 0px 4px;
        border-radius: 10%;

          color: rgba(250, 179, 135, 0.6); 
          transition: all 0.3s ease;
      }

      #custom-home.active {
          color: #fab387; /* Exemplo de cor sólida */
          background-color: rgba(250, 179, 135, 0.15);
          border-bottom: 2px solid #fab387; /* Exemplo de cor sólida */

        padding-top: 4px;
        padding-left: 12px;
        padding-right: 12px;
      }

      #custom-home:hover {
          color: @peach;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        "margin-top" = 0;
        "margin-bottom" = 0;

        modules-left = [
          "custom/home"
          "custom/sep"
          "hyprland/workspaces"
          "custom/sep"
          "hyprland/window"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "cpu"
          "memory"
          "network"
          "pulseaudio"
          "custom/audio-switcher"
          "custom/power"
        ];

        "custom/home" = {
          format = "";
          return-type = "json";
          signal = 8;
          exec = "~/.config/waybar/scripts/workspacer.sh";
          interval = 1;
          on-click = "~/.config/hypr/scripts/toggle_special.sh";
          tooltip = false;
        };

        "hyprland/workspaces" = {
          all-outputs = false;
          active-only = false;
          persistent-only = true;
          persistent-workspaces = {
            "1" = []; "2" = []; "3" = []; "4" = []; "5" = [];
            "6" = []; "7" = []; "8" = []; "9" = [];
          };
        };

        "hyprland/window" = {
          format = "{title}";
          max-length = 45;
          separate-outputs = true;
        };

        "custom/sep" = {
          format = "|";
          tooltip = false;
        };

        "network" = {
          format-wifi = "  {essid}";
          format-ethernet = "";
          format-disconnected = "  Offline";
        };

        "cpu" = {
          format = "󰘚 {usage: >3}%";
          on-click = "pypr toggle btop";
        };

        "memory" = {
          format = " {: >3}%";
          on-click = "pypr toggle btop";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "  0%";
          format-icons = {
            default = ["" "" ""];
          };
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pypr toggle volume";
        };

        "custom/audio-switcher" = {
          format = "{}";
          exec = "~/.config/waybar/scripts/audio_switcher.sh";
          on-click = "~/.config/waybar/scripts/audio_switcher.sh switch";
          interval = 1;
          return-type = "json";
        };

        "clock" = {
          format = "  {:%a %d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "custom/power" = {
          format = "";
          on-click = "quickshell -p ~/.config/waybar/scripts/powermenu.qml";
          tooltip = false;
        };
      };
    };
  };
}