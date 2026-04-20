#!/usr/bin/env bash
set -euo pipefail

ssh-hosts.sh | sed 's/^/ssh /'

candidates=("$HOME/.dotfiles")
while IFS= read -r d; do
  candidates+=("$d")
done < <(find "$HOME/VIRTO" "$HOME/VIRTO/experiments" "$HOME/dev" \
  -mindepth 1 -maxdepth 1 -type d)

{
  find "${candidates[@]}" -mindepth 1 -maxdepth 1 -printf '%A@\t%h\n'
  printf '0\t%s\n' "${candidates[@]}"
} | sort -rn -k1,1 | awk -F'\t' '!seen[$2]++'
