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
alias -g dfif='diff'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# pnpm
export PNPM_HOME="/home/bastiaan/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end
# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
