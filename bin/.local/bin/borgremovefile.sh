#!/bin/sh

set -x
set -e

echo READ THIS FILE BEFORE EXECUTING
exit 1

export BORG_REPO=ssh://u402432@u402432.your-storagebox.de:23/./borg-repository
export BORG_PASSPHRASE=$(cat /home/bastiaan/.ssh/borg_backup_passphrase)



FILE_TO_DELETE="home/bastiaan/VIRTO/dbDumps/prod_virtomax-vs360_modules_database_microservice-2024-10-09.agz"

# List all archives
# ARCHIVES=$(borg list --short $BORG_REPO)

ARCHIVE=bastiaan-thinkpad-2024-12-01T20:48:01


# List all the archives
borg list $BORG_REPO

# List the files matching the pattern in the archive
borg list $BORG_REPO::bastiaan-thinkpad-2024-10-31T13:16:00  --pattern='+ re:2024-10-09\.agz$' −−pattern '− re:ˆ.*$'

# recreate all archives in repo excluding the matching files
borg recreate $BORG_REPO --exclude 're:-2024-10-09\.agz$'

