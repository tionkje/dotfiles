#!/bin/sh
cd $(dirname $0);

ln -sf $(pwd)/dot_vimrc ~/.vimrc

mkdir -p ~/.vim/bundle
# ln -sfn $(pwd)/Vundle.vim ~/.vim/bundle/vundle
rm -rf ~/.vim/bundle/vundle;
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/vundle;

vim +PluginInstall +qall

mkdir -p ~/.vim/backup
mkdir -p ~/.vim/undo
mkdir -p ~/.vim/swap

ln -sf $(pwd)/dot_tmux.conf ~/.tmux.conf

ln -sf $(pwd)/dot_eslintrc ~/.eslintrc
