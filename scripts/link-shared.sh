#!/usr/bin/env bash

ln -vsf $(pwd)/../shared/zsh/.zshrc $HOME/.zshrc
ln -vsf $(pwd)/../shared/zsh/.zsh_history $HOME/.zsh_history
ln -vsf $(pwd)/../shared/git/.gitconfig $HOME/.gitconfig

rm -rf $HOME/.config/tmux
ln -vsfd $(pwd)/../shared/tmux $HOME/.config/tmux

rm -rf $HOME/.config/nvim
ln -vsfd $(pwd)/../shared/nvim $HOME/.config/nvim

rm -rf $HOME/.config/scripts
ln -vsfd $(pwd)/../shared/scripts $HOME/.config/scripts
