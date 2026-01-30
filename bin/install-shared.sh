#!/usr/bin/env bash

source $DOT_DIR/bin/cmds.sh

PKGS=("fastfetch" "otf-font-awesome" "ttf-jetbrains-mono" "texlive-fontsextra" "ttf-jetbrains-mono-nerd" "man-db" "tealdeer" "wikiman" "arch-wiki-docs" "neovim" "npm" "deno" "cmake" "gcc" "llvm" "luarocks" "unzip" "lua" "wl-clipboard" "clang" "tmux" "fzf" "bat" "go")

if check_if_updates; then
	update_pacman 
fi

if ! check_if_present git; then
	install_package_pacman git
else
	echo -e "\033[34mgit\033[0m is already installed"
fi

if ! check_if_present paru; then
	install_paru 
else
	echo -e "\033[34mparu\033[0m is already installed"
fi

for pkg in "${PKGS[@]}"; do
	if ! check_if_present $pkg; then
		install_package_paru $pkg
	else
		echo -e "\033[34m$pkg\033[0m is already installed"
	fi
done
echo

if check_if_updates; then
	update_pacman 
fi

echo -e "\033[32mAll packages are up to date.\033[0m"
echo
