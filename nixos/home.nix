 config, pkgs, inputs, ... }:

{
  home.username = "jgfer";
  home.homeDirectory = "/home/jgfer";
  home.stateVersion = "24.11";

  # Mapeamento declarativo dos arquivos do repositório
  xdg.configFile = {
    # Mapeia a pasta Hyprland do repositório para o ~/.config/hypr
    "hypr".source = "${inputs.my-dotfiles}/arch-desktop/hypr";
    
    # Mapeia Waybar
    "waybar".source = "${inputs.my-dotfiles}/arch-desktop/waybar";
    
    # Mapeia Neovim (Shared)
    "nvim".source = "${inputs.my-dotfiles}/shared/nvim";
    
    # Caso queira mapear arquivos individuais:
    # "kitty/kitty.conf".source = "${inputs.my-dotfiles}/shared/kitty/kitty.conf";
  };

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
