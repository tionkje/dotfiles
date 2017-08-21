#!/bin/bash

doinstall(){
  scp dot_vimrc $1:~/.vimrc

  ssh -t $1 '
  mkdir -p ~/.vim/backup
  mkdir -p ~/.vim/undo
  mkdir -p ~/.vim/swap

  mkdir -p ~/.vim/bundle
  rm -rf ~/.vim/bundle/vundle;
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/vundle;

  vim +PluginInstall! +qall

  '
}

doinstall lucky@front
doinstall lucky@hub
doinstall lucky@game
doinstall lucky@account
