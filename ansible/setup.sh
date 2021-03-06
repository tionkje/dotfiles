#!/bin/bash
function go () {
  cd ~
  sudo apt update
  sudo apt install ansible git -y;

  ansible-pull -U git@github.com:tionkje/dotfiles.git -d ~/dotfiles ansible/playbook.yml;

  echo run these commands to get dropbox running
  echo "~/dropbox.py start -i"
  echo "~/dropbox.py status"


  source ~/.nvm/nvm.sh
  nvm install node
  
  vim +PlugInstall +qall

  zsh
}
go
