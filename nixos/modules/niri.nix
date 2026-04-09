{ config, pkgs, inputs, ... }:

{
  xdg.configFile."niri/config.kdl".source = inputs.my-dotfiles + "/arch-desktop/niri/config.kdl";
}