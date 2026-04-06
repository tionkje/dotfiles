#!/usr/bin/env bash
ssh-hosts.sh | sed 's/^/ssh /'
echo ~/.dotfiles
find ~/VIRTO ~/VIRTO/experiments ~/dev/ -mindepth 1 -maxdepth 1 -type d
