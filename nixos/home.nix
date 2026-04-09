{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/terminal.nix
    ./modules/shell.nix
    ./modules/tmux.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/wofi.nix
    ./modules/desktop-extras.nix
    ./modules/nvim.nix
    ./modules/niri.nix
  ];

  home.username = "jgfer";
  home.homeDirectory = "/home/jgfer";
  home.stateVersion = "25.05";

  programs.bash = {
    enable = true;
    shellAliases = {
      teste = "echo isso eh um teste";
      nos-rebuild = "sudo nixos-rebuild switch --flake .#nixpc";
    };
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec Hyprland
      fi
    '';
  };

  # Ativando o gerenciamento de pacotes via home-manager
  programs.home-manager.enable = true;
}
