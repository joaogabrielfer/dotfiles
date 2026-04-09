{ config, pkgs, inputs, ... }:

{
  xdg.configFile = {
    "alacritty/alacritty.toml".text = builtins.replaceStrings
      [ ''program = "/usr/bin/fish"'' ]
      [ ''program = "${pkgs.fish}/bin/fish"'' ]
      (builtins.readFile (inputs.my-dotfiles + "/arch-desktop/alacritty/alacritty.toml"));

    "ghostty/config".source = "${inputs.my-dotfiles}/arch-desktop/ghostty/config";
  };
}