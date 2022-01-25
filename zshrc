HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=1000000
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS

setopt AUTO_PUSHD

bindkey -e

# source <(antibody init)
# antibody bundle < ~/.zsh_plugins.txt
source ~/.zsh_plugins.sh

# get git info
# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }
# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%b'
# Set up the prompt (with git branch name)
autoload -U colors && colors
setopt PROMPT_SUBST
PROMPT='%(1j. %j .)%{$fg_bold[red]%}${vcs_info_msg_0_} %{$fg_no_bold[yellow]%}${PWD/#$HOME/~}%{$reset_color%} > '


csdiff () {
  echo 'csdiff' "$1" "$2";
  # dwdiff --algorithm=best --context=4 --punctuation --color --aggregate-changes $*
  diff -u "$1" "$2" | diff-so-fancy
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


alias ls='ls --color=auto -lA'
