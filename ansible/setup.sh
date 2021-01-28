#!/bin/bash
function go () {
  sudo apt update
  sudo apt install ansible git -y;

  ansible-pull -U https://github.com/tionkje/dotfiles.git -d dotfiles ansible/playbook.yml;

  ~/dropbox.py update
  ~/dropbox.py status
}
go
