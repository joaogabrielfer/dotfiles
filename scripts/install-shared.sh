#!/usr/bin/env bash
sudo pacman --noconfirm -Syu git

sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

paru --noconfirm -S \
	fastfetch \
	otf-font-awesome \
	ttf-jetbrains-mono \
	texlive-fontsextra \
	ttf-jetbrains-mono-nerd \
	man-db \
	tealdeer \
	wikiman \
	arch-wiki-docs \
	neovim \
	npm \
	deno \
	cmake \
	gcc \
	llvm \
	luarocks \
	unzip \
	lua \
	wl-clipboard \
	clang \
	tmux \
	fzf \
	bat \
	go \
