#!/bin/sh

set -x
set -e

# echo READ THIS FILE BEFORE EXECUTING
# exit 1

export BORG_REPO=ssh://u402432@u402432.your-storagebox.de:23/./borg-repository
export BORG_PASSPHRASE=$(cat /home/bastiaan/.ssh/borg_backup_passphrase)


# List all archives
# ARCHIVES=$(borg list --short $BORG_REPO)


LAST_ARCHIVE_DATE=$(/bin/ls ~/VIRTO/dbDumps/ -t | tail -n 1 | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' -o)

# List all the archives
# borg list $BORG_REPO

# Fill in this variable with the latest archive of above
LAST_ARCHIVE=$(borg list --last 1 -a bastiaan-* | awk '{print $1}')

# List the files matching the pattern in the archive
borg list $BORG_REPO::$LAST_ARCHIVE  --pattern='+ re:'"$LAST_ARCHIVE_DATE"'\.agz$' −−pattern '− re:ˆ.*$'

read -p "borg recreate $BORG_REPO --exclude 're:-${LAST_ARCHIVE_DATE}\.agz$' ?"
# recreate all archives in repo excluding the matching files
borg recreate $BORG_REPO --exclude 're:-'"$LAST_ARCHIVE"'\.agz$'

read -p "rm -rf ~/VIRTO/dbDumps/*${LAST_ARCHIVE_DATE}.agz ?"
rm -rf ~/VIRTO/dbDumps/*${LAST_ARCHIVE_DATE}.agz
