{ config, pkgs, ...} :

{
        home.username = "jgfer";
        home.homeDirectory = "/home/jgfer";
        home.stateVersion = "25.05";
        programs.bash = {
                enable = true;
                shellAliases = {
                        teste = "echo isso eh um teste";
                };
                profileExtra = ''
                        if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
                                exec hyprland
                        fi
                '';
        };
}
