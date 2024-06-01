#!/bin/sh

set -x

export BORG_REPO=ssh://u402432@u402432.your-storagebox.de:23/./borg-repository
export BORG_PASSPHRASE=$(cat /home/bastiaan/.ssh/borg_backup_passphrase)


# hardcode option for speed
# LAST_ARCHIVE=$(borg list --last 1 -a bastiaan-XPS-13-9300* | awk '{print $1}')
LAST_ARCHIVE="bastiaan-XPS-13-9300-2024-05-29T09:03:44"


ARCHIVE=$BORG_REPO::$LAST_ARCHIVE

# list contents of .ssh directory
# borg list $ARCHIVE /home/bastiaan/.ssh

# extract .ssh folder to current directory
# borg extract --strip-components 2 $ARCHIVE /home/bastiaan/.ssh



# list all folders in my dev folder. 8 is column for file in borg list. 4 is path of name
# I used it to check nothing gets overwritten in my current dev folder
# borg list $ARCHIVE /home/bastiaan/dev | awk '{print $8}' | awk -F '/' '{print $4}' | sort | uniq


# restore dev folder from backup
# pushd ~/dev
# borg extract --progress --strip-components 3 $ARCHIVE /home/bastiaan/dev
# popd

# restore VIRTO folder
# pushd ~/
# borg extract --progress --strip-components 2 $ARCHIVE /home/bastiaan/VIRTO
# popd

# restore history file
# pushd /tmp
# borg extract --progress --strip-components 2 $ARCHIVE /home/bastiaan/.histfile
# popd


# restore wifi passwords
# borg list $ARCHIVE /etc/NetworkManager/

# pushd /tmp
# borg extract --progress --strip-components 2 $ARCHIVE /etc/NetworkManager/system-connections
# popd
# TODO: copy manually to correct place (requires sudo) and change wireless device name


# restore screenshots
# borg list $ARCHIVE /home/bastiaan/Pictures/
# pushd /home/bastiaan/Pictures
# borg extract --progress --strip-components 3 $ARCHIVE /home/bastiaan/Pictures
# popd
