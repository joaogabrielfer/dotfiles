#! usr/bin/bash
sudo pacman -Syu git

sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

sudo pacman -R kitty dolphin

paru --noconfirm -S zen-browser-binary elecwhat-bin spotify
paru --noconfirm -S hyprpaper hypridle hyprshot hyprlock hyprpicker swaync waypaper waybar fastfetch otf-font-awesome ttf-jetbrains-mono texlive-fontsextra ttf-jetbrains-mono-nerd

paru --noconfirm -S man-db pavucontrol ghostty sddm nsxiv tealdeer wikiman arch-wiki-docs
sudo systemctl enable -f sddm.service

paru --noconfirm -S neovim npm deno cmake gcc llvm luarocks unzip lua wl-clipboard clang
paru --noconfirm -S tmux fzf bat
paru --noconfirm -S go
