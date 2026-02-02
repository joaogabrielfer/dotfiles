#!/usr/bin/env bash

ln -vsf $DOT_DIR/arch-desktop/user-dirs.dirs $HOME/.config/user-dirs.dirs
ln -vsf $DOT_DIR/arch-desktop/user-dirs.locale $HOME/.config/user-dirs.locale

rm -rf $HOME/.config/ghostty
ln -vsfd $DOT_DIR/arch-desktop/ghostty $HOME/.config/ghostty

rm -rf $HOME/.config/hypr
ln -vsfd $DOT_DIR/arch-desktop/hypr $HOME/.config/hypr

rm -rf $HOME/.config/swaync
ln -vsfd $DOT_DIR/arch-desktop/swaync $HOME/.config/swaync

rm -rf $HOME/.config/wallpapers
ln -vsfd $DOT_DIR/arch-desktop/wallpapers $HOME/.config/wallpapers

rm -rf $HOME/.config/waybar
ln -vsfd $DOT_DIR/arch-desktop/waybar $HOME/.config/waybar

rm -rf $HOME/.config/waypaper
ln -vsfd $DOT_DIR/arch-desktop/waypaper $HOME/.config/waypaper

rm -rf $HOME/.config/wofi
ln -vsfd $DOT_DIR/arch-desktop/wofi $HOME/.config/wofi

# dir alacritty to link in $HOME/.config/alacritty
rm -rf $HOME/.config/alacritty
ln -vsf $DOT_DIR/arch-desktop/alacritty $HOME/.config/alacritty
# dir pypr to link in $HOME/.config/pypr
rm -rf $HOME/.config/pypr
ln -vsf $DOT_DIR/arch-desktop/pypr $HOME/.config/pypr
