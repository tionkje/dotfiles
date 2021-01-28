#!/bin/bash
function go () {
  sudo apt update
  sudo apt install ansible -y;
  ansible-pull -U https://github.com/tionkje/dotfiles.git -d dotfiles ansible/playbook.yml
}
go
