# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=1000000
bindkey -e

autoload -Uz compinit
compinit -i
# End of lines added by compinstall
echo "Parsing ~/.zshrc"

alias ll='ls --color=auto -la'
alias ls='ls --color=auto -lA'
alias ct='cleartool'
alias cr='dos2unix'
alias v='vim'
alias cd..='cd ..'

eval `dircolors -b`

setopt AUTO_CD
setopt INC_APPEND_HISTORY
setopt BASH_AUTO_LIST
setopt AUTO_PUSHD
unsetopt AUTO_RESUME
setopt HIST_IGNORE_DUPS
unsetopt NOMATCH
#disable interpretation of backslash in echo
setopt BSD_ECHO

#case insensitive completion with priority on case match (empty string is exact match)
compctl -M '' 'm:{a-zA-Z}={A-Za-z}'
autoload -U colors && colors

# If this is an xterm set the title to user@host:dir
case $TERM in
    xterm*)
        precmd () {print -Pn "\e]0;%~\a"}
        ;;
esac


# key bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "^H" backward-delete-word
# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# for non RH/Debian xterm, can't hurt for RH/DEbian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix


csdiff () {
  echo 'csdiff' "$1" "$2";
  dwdiff --algorithm=best --context=4 --punctuation --color --aggregate-changes $*
}

export EDITOR=vim

SSH_ENV="$HOME/.ssh/env"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    source "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add ~/.ssh/agl_rsa;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    source "${SSH_ENV}" > /dev/null
    ps -F ${SSH_AGENT_PID} > /dev/null || start_agent;
else
    start_agent;
fi

echo 'Current keys in agent:'
ssh-add -l



# for VIM and TMUX
if [ "$TERM" = "screen" ]; then
  export TERM=xterm-256color
fi

# get git info
# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }
# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%b'
# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%(1j. %j .)%{$fg_bold[red]%}${vcs_info_msg_0_} %{$fg_no_bold[yellow]%}${PWD/#$HOME/~}%{$reset_color%} > '


fpath=(~/.zsh/completion $fpath)
export TERM=xterm-256color

export LIBGL_ALWAYS_INDIRECT=1

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/__tabtab.zsh ]] && . ~/.config/tabtab/__tabtab.zsh || true
