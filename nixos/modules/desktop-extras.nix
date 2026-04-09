{ config, pkgs, inputs, ... }:

{
  xdg.configFile = {
    # Desktop tools
    "pypr/config.toml".source = "${inputs.my-dotfiles}/arch-desktop/pypr/config.toml";
    "swaync".source = "${inputs.my-dotfiles}/arch-desktop/swaync";
    "waypaper/config.ini".text = builtins.replaceStrings 
      [ "/home/joaogabriel" ] 
      [ config.home.homeDirectory ] 
      (builtins.readFile (inputs.my-dotfiles + "/arch-desktop/waypaper/config.ini"));

    # Scripts for Waybar and Hyprland
    "hypr/scripts".source = "${inputs.my-dotfiles}/arch-desktop/hypr/scripts";
    "waybar/scripts".source = "${inputs.my-dotfiles}/arch-desktop/waybar/scripts";
    "wofi/scripts".source = "${inputs.my-dotfiles}/arch-desktop/wofi/scripts";
  };
}