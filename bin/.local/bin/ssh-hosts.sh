#!/usr/bin/env zsh

# Better completion for ssh in Zsh.
# https://github.com/sunlei/zsh-ssh
# v0.0.7
# Copyright (c) 2020 Sunlei <guizaicn@gmail.com>

setopt no_beep # don't beep

SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"

# Parse the file and handle the include directive.
_parse_config_file() {
  # Enable PCRE matching
  setopt localoptions rematchpcre
  unsetopt nomatch

  local config_file_path=$(realpath "$1")
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ ^[Ii]nclude[[:space:]]+(.*) ]] && (( $#match > 0 )); then
      local include_path="${match[1]}"
      if [[ $include_path == ~* ]]; then
        # Replace the first occurrence of "~" in the string with the value of the environment variable HOME.
        local expanded_include_path=${include_path/#\~/$HOME}
      else
        local expanded_include_path="$HOME/.ssh/$include_path"
      fi
      # `~` used to force the expansion of wildcards in variables
      for include_file_path in $~expanded_include_path; do
        if [[ -f "$include_file_path" ]]; then
          # Insert a blank line between the included files
          echo ""
          _parse_config_file "$include_file_path"
        fi
      done
    else
      echo "$line"
    fi
  done < "$config_file_path"
}

_ssh_host_list() {
  local ssh_config host_list

  ssh_config=$(_parse_config_file $SSH_CONFIG_FILE)
  ssh_config=$(echo $ssh_config | command grep -v -E "^\s*#[^_]")

  host_list=$(echo $ssh_config | command awk '
    function join(array, start, end, sep, result, i) {
      # https://www.gnu.org/software/gawk/manual/html_node/Join-Function.html
      if (sep == "")
        sep = " "
      else if (sep == SUBSEP) # magic value
        sep = ""
      result = array[start]
      for (i = start + 1; i <= end; i++)
        result = result sep array[i]
      return result
    }

    function parse_line(line) {
      n = split(line, line_array, " ")

      key = line_array[1]
      value = join(line_array, 2, n)

      return key "#-#" value
    }

    function contains_star(str) {
        return index(str, "*") > 0
    }

    function starts_or_ends_with_star(str) {
        start_char = substr(str, 1, 1)
        end_char = substr(str, length(str), 1)

        return start_char == "*" || end_char == "*"
    }

    BEGIN {
      IGNORECASE = 1
      FS="\n"
      RS=""

      nrec = 0
    }
    {
      match_directive = ""
      user = " "
      host_name = ""
      aliases = ""
      desc = ""
      desc_formated = " "

      for (line_num = 1; line_num <= NF; ++line_num) {
        line = parse_line($line_num)
        split(line, tmp, "#-#")
        key = tolower(tmp[1])
        value = tmp[2]

        if (key == "match") { match_directive = value }
        if (key == "host") { aliases = value }
        if (key == "user") { user = value }
        if (key == "hostname") { host_name = value }
        if (key == "#_desc") { desc = value }
      }

      if (desc) {
        desc_formated = sprintf("[\033[00;34m%s\033[0m]", desc)
      }

      split(aliases, alias_list, " ")
      for (i in alias_list) {
        alias = alias_list[i]
        if (starts_or_ends_with_star(alias) || match_directive) continue

        hn = host_name ? host_name : alias
        if (starts_or_ends_with_star(hn)) continue

        nrec++
        rec_alias[nrec] = alias
        rec_hn[nrec] = hn
        rec_user[nrec] = user
        rec_desc[nrec] = desc_formated
        rec_implicit[nrec] = (hn == alias) ? 1 : 0

        if (hn != alias) alias_has_explicit[alias] = 1
      }
    }
    END {
      # Pass 1: skip implicit entries (alias==hostname) when an explicit one exists
      host_count = 0
      for (i = 1; i <= nrec; i++) {
        if (rec_implicit[i] && alias_has_explicit[rec_alias[i]]) continue

        hn = rec_hn[i]
        alias = rec_alias[i]

        if (!(hn in host_aliases)) {
          host_aliases[hn] = alias
          seen_alias[hn, alias] = 1
          host_users[hn] = rec_user[i]
          host_descs[hn] = rec_desc[i]
          host_count++
          host_order[hn] = host_count
          order_to_hn[host_count] = hn
        } else {
          if (!seen_alias[hn, alias]) {
            host_aliases[hn] = host_aliases[hn] ", " alias
            seen_alias[hn, alias] = 1
          }
        }
      }

      # Pass 2: output in insertion order
      for (i = 1; i <= host_count; i++) {
        hn = order_to_hn[i]
        printf "%s | %s | %s | %s\n", host_aliases[hn], hn, host_users[hn], host_descs[hn]
      }
    }
  ')

  for arg in "$@"; do
    case $arg in
    -*) shift;;
    *) break;;
    esac
  done

  host_list=$(command grep -i "$1" <<< "$host_list")
  host_list=$(echo $host_list | command sort -u)

  echo $host_list
}


_fzf_list_generator() {
  local header host_list

  if [ -n "$1" ]; then
    host_list="$1"
  else
    host_list=$(_ssh_host_list)
  fi

  header="
Alias|->|Hostname|User|Desc
─────|──|────────|────|────
"

  host_list="${header}\n${host_list}"

  echo $host_list | command column -t -s '|'
}

_set_lbuffer() {
  local result selected_host connect_cmd is_fzf_result
  result="$1"
  is_fzf_result="$2"

  if [ "$is_fzf_result" = false ] ; then
    result=$(cut -f 1 -d "|" <<< ${result})
  fi

  selected_host=$(cut -f 1 -d " " <<< ${result})
  connect_cmd="ssh ${selected_host}"

  LBUFFER="$connect_cmd"
}
_ssh_host_list
#
# fzf_complete_ssh() {
#   local tokens cmd result selected_host
#   setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
#
#   tokens=(${(z)LBUFFER})
#   cmd=${tokens[1]}
#
#   if [[ "$LBUFFER" =~ "^ *ssh$" ]]; then
#     zle ${fzf_ssh_default_completion:-expand-or-complete}
#   elif [[ "$cmd" == "ssh" ]]; then
#     result=$(_ssh_host_list ${tokens[2, -1]})
#
#     if [ -z "$result" ]; then
#       zle ${fzf_ssh_default_completion:-expand-or-complete}
#       return
#     fi
#
#     if [ $(echo $result | wc -l) -eq 1 ]; then
#       _set_lbuffer $result false
#       zle reset-prompt
#       # zle redisplay
#       return
#     fi
#
#     result=$(_fzf_list_generator $result | fzf \
#       --height 40% \
#       --ansi \
#       --border \
#       --cycle \
#       --info=inline \
#       --header-lines=2 \
#       --reverse \
#       --prompt='SSH Remote > ' \
#       --no-separator \
#       --bind 'shift-tab:up,tab:down,bspace:backward-delete-char/eof' \
#       --preview 'ssh -T -G $(cut -f 1 -d " " <<< {}) | grep -i -E "^User |^HostName |^Port |^ControlMaster |^ForwardAgent |^LocalForward |^IdentityFile |^RemoteForward |^ProxyCommand |^ProxyJump " | column -t' \
#       --preview-window=right:40%
#     )
#
#     if [ -n "$result" ]; then
#       _set_lbuffer $result true
#       zle accept-line
#     fi
#
#     zle reset-prompt
#     # zle redisplay
#
#   # Fall back to default completion
#   else
#     zle ${fzf_ssh_default_completion:-expand-or-complete}
#   fi
# }


# [ -z "$fzf_ssh_default_completion" ] && {
#   binding=$(bindkey '^I')
#   [[ $binding =~ 'undefined-key' ]] || fzf_ssh_default_completion=$binding[(s: :w)2]
#   unset binding
# }


# zle -N fzf_complete_ssh
# bindkey '^I' fzf_complete_ssh

# vim: set ft=zsh sw=2 ts=2 et
