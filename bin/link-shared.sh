#!/usr/bin/env bash

ln -vsf $DOT_DIR/shared/zsh/.zshrc $HOME/.zshrc
ln -vsf $DOT_DIR/shared/git/.gitconfig $HOME/.gitconfig

rm -rf $HOME/.config/tmux
ln -vsfd $DOT_DIR/shared/tmux $HOME/.config/tmux

rm -rf $HOME/.config/nvim
ln -vsfd $DOT_DIR/shared/nvim $HOME/.config/nvim

rm -rf $HOME/.config/scripts
ln -vsfd $DOT_DIR/shared/scripts $HOME/.config/scripts
