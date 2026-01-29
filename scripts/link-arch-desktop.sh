#!/usr/bin/env bash

ln -vsf $(pwd)/../arch-desktop/user-dirs.dirs $HOME/.config/user-dirs.dirs
ln -vsf $(pwd)/../arch-desktop/user-dirs.locale $HOME/.config/user-dirs.locale

rm -rf $HOME/.config/ghostty
ln -vsfd $(pwd)/../arch-desktop/ghostty $HOME/.config/ghostty

rm -rf $HOME/.config/hypr
ln -vsfd $(pwd)/../arch-desktop/hypr $HOME/.config/hypr

rm -rf $HOME/.config/swaync
ln -vsfd $(pwd)/../arch-desktop/swaync $HOME/.config/swaync

rm -rf $HOME/.config/wallpapers
ln -vsfd $(pwd)/../arch-desktop/wallpapers $HOME/.config/wallpapers

rm -rf $HOME/.config/waybar
ln -vsfd $(pwd)/../arch-desktop/waybar $HOME/.config/waybar

rm -rf $HOME/.config/waypaper
ln -vsfd $(pwd)/../arch-desktop/waypaper $HOME/.config/waypaper

rm -rf $HOME/.config/wofi
ln -vsfd $(pwd)/../arch-desktop/wofi $HOME/.config/wofi
