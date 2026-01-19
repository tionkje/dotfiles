#!/usr/bin/env zsh

# Print first alias of each configured SSH host
# Based on ssh-hosts.sh

setopt no_beep

SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"

_parse_config_file() {
  setopt localoptions rematchpcre
  unsetopt nomatch

  local config_file_path=$(realpath "$1")
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ ^[Ii]nclude[[:space:]]+(.*) ]] && (( $#match > 0 )); then
      local include_path="${match[1]}"
      if [[ $include_path == ~* ]]; then
        local expanded_include_path=${include_path/#\~/$HOME}
      else
        local expanded_include_path="$HOME/.ssh/$include_path"
      fi
      for include_file_path in $~expanded_include_path; do
        if [[ -f "$include_file_path" ]]; then
          _parse_config_file "$include_file_path"
        fi
      done
    else
      echo "$line"
    fi
  done < "$config_file_path"
}

_ssh_host_list() {
  local ssh_config

  ssh_config=$(_parse_config_file $SSH_CONFIG_FILE)
  # Remove comments
  ssh_config=$(echo $ssh_config | command grep -v -E "^\s*#")

  echo $ssh_config | command awk '
    BEGIN { IGNORECASE = 1 }
    /^[[:space:]]*[Hh]ost[[:space:]]+/ {
      # Get everything after "Host "
      sub(/^[[:space:]]*[Hh]ost[[:space:]]+/, "")
      # Get first alias only
      split($0, aliases, " ")
      alias = aliases[1]
      # Skip wildcards
      if (alias !~ /\*/) {
        print alias
      }
    }
  ' | sort -u
}

_ssh_host_list
