{ config, pkgs, inputs, ... }:

{
  xdg.configFile."nvim".source = "${inputs.my-dotfiles}/shared/nvim";
}