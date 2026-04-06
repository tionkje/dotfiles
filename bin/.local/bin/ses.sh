#!/usr/bin/env bash

#source $HOME/.zshrc
export PATH="$PATH:$HOME/.local/bin"

export TERM=xterm-256color

# tmux list-sessions -F '#{session_name}'  -f "#{!=:#{session_name},$(tmux display-message -p '#S')}"

# echo $PATH
# ssh-hosts.sh

# sleep 1

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(ses-entries.sh | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

tmux_running=$(pgrep tmux)

if [[ "${selected%% *}" = "ssh" ]]; then

  eval `loadKeys.sh`;

  temp="${selected#* }"
  first_alias="${temp%%[, |]*}"
  cmd="ssh ${first_alias}"
  selected_name="ssh_${first_alias//./_}"
  echo "ssh -o ConnectTimeout=5 -q ${first_alias} exit"
  if ssh -o ConnectTimeout=5 -q ${first_alias} exit; then

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux -2 new-session -s "$selected_name" -c ~ zsh -c "export TERM=xterm-256color; $cmd"
        # tmux send-keys -t $selected_name "vim ." C-m
        exit 0
    fi

    echo selected_name: $selected_name
    if ! tmux has-session -t="$selected_name" 2> /dev/null; then
        tmux -2 new-session -ds "$selected_name" -c ~ zsh -c "export TERM=xterm-256color; $cmd"
        # tmux send-keys -t $selected_name "vim ." C-m
    fi
  else
    echo "Could not connect to $temp"
  fi
else
  echo selected: ${selected[0]}

  selected_name=$(basename "$selected" | tr . _)

  if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
      tmux new-session -s $selected_name -c $selected
      # tmux send-keys -t $selected_name "vim ." C-m
      exit 0
  fi

  if ! tmux has-session -t=$selected_name 2> /dev/null; then
      tmux new-session -ds $selected_name -c $selected
  fi

fi

tmux switch-client -t "$selected_name"

# tmux send-keys -t $selected_name "vim ." C-m
