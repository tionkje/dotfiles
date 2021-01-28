#!/bin/bash
function go () {
  cd ~
  sudo apt update
  sudo apt install ansible git -y;

  ansible-pull -U https://github.com/tionkje/dotfiles.git -d ~/dotfiles ansible/playbook.yml;

  ~/dropbox.py start -i
  ~/dropbox.py status
}
go
