#!/usr/bin/env bash

# pipe stdout to stderr and hold a backup of stdout in fd 3
exec 3>&1 1>&2

# set -x

# apt-get install expect
# pacman -S expect

# Function to start a new ssh-agent and save its settings
start_new_agent() {
    echo "Starting ssh-agent"
    (umask 066; ssh-agent > ~/.ssh-agent)
    eval "$(<~/.ssh-agent)" >/dev/null
}

# Function to check if current env matches stored agent
env_matches_stored() {
    if [ ! -r ~/.ssh-agent ]; then
        return 1
    fi
    local stored_sock=$(grep -oP 'SSH_AUTH_SOCK=\K[^;]+' ~/.ssh-agent)
    [ "$SSH_AUTH_SOCK" = "$stored_sock" ]
}

# Function to check if stored agent is still running
stored_agent_is_running() {
    if [ ! -r ~/.ssh-agent ]; then
        return 1
    fi
    eval "$(<~/.ssh-agent)" >/dev/null
    ssh-add -l &>/dev/null
    [ "$?" != 2 ]
}

# Ensure agent is running
ssh-add -l &>/dev/null
agent_status=$?

if [ "$agent_status" == 2 ]; then
    # No connection to agent - try loading stored one
    if stored_agent_is_running; then
        echo "Loading ssh-agent from ~/.ssh-agent"
    else
        start_new_agent
    fi
elif ! env_matches_stored; then
    # Agent running but doesn't match stored settings
    echo "Current agent doesn't match ~/.ssh-agent"
    if stored_agent_is_running; then
        echo "Loading ssh-agent from ~/.ssh-agent"
    else
        start_new_agent
    fi
fi

# if [ -z "$SSH_AUTH_SOCK" ] ; then
#   echo "Starting ssh-agent"
#   eval `ssh-agent -s`
# fi


# ssh-add -l

set -e

# echo "Please enter your password:"
# read -s password

SSH_KEYS=$(/bin/ls ~/.ssh/virto | ag 512$ )
# SSH_KEYS=$(/bin/ls ~/.ssh/virto | ag 512$ | ag -v 'sunbeamv1|avasco_prod_|bitbucket|compri')

for key in $SSH_KEYS; do
  key=~/.ssh/virto/$key;
  FINGERPRINT=$(ssh-keygen -lf $key | awk '{print $2}')
  # echo "Fingerprint: $FINGERPRINT"

  if ssh-add -l | grep $FINGERPRINT &>/dev/null; then
    # echo "Key $key already added"
    continue
  fi

  if [ -z "$password" ]; then
    keepassxc-cli show -s -a password ~/Dropbox/mykeys.kdbx /VIRTO/virto_ecdsa | tr -d '\n' | xclip -i;
    echo "Please enter your password:"
    read -s password
  fi

  echo "Adding key $key"
  # Add key to ssh-agent
  expect -c "
    spawn ssh-add $key
    expect \"Enter passphrase for $key:\"
    send \"$password\r\"
    expect eof
    "
done

echo ""
echo "Keys loaded:"
echo ""
ssh-add -l

echo "Exporting SSH_AUTH_SOCK and SSH_AGENT_PID"
echo "export SSH_AUTH_SOCK=\"$SSH_AUTH_SOCK\"; export SSH_AGENT_PID=\"$SSH_AGENT_PID\"; " >&3
