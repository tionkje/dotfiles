#!/bin/sh


# ssh  -i /home/bastiaan/.ssh/hetzner_borgbackup_2024 -p23 u402432@u402432.your-storagebox.de ls -la /home/borg-repository
# ssh  -i /home/bastiaan/.ssh/hetzner_borgbackup_2024 -p23 u402432@u402432.your-storagebox.de cat /home/borg-repository/README
# exit

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/snap/bin

#BORG_RSH='ssh -i ~/.ssh/hetzner_borgbackup_2024' borg init --encryption=repokey ssh://u402432@u402432.your-storagebox.de:23/./borg-repository

# Setting this, so the repo does not need to be given on the commandline:
#export BORG_REPO=ssh://username@example.com:2022/~/backup/main
export BORG_REPO=ssh://u402432@u402432.your-storagebox.de:23/./borg-repository
export BORG_RSH='ssh -oBatchMode=yes -i /home/bastiaan/.ssh/hetzner_borgbackup_2024'


# See the section "Passphrase notes" for more infos.
export BORG_PASSPHRASE=$(.ssh/.ssh/borg_backup_passphrase)

if [ ! -z "$BORG_LIST" ]; then
borg list
exit;
fi

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude 'home/*/.cache/*'     \
    --exclude 'var/tmp/*'           \
    --exclude '*/.local/share/pnpm/*'           \
    --exclude '*/AGL/*'           \
    --exclude '*/.config/google-chrome*'           \
    --exclude '*/.config/Insync' \
    --exclude '*/.config/Slack' \
    --exclude '*/.local/state'           \
    --exclude '*/.local/share'           \
    --exclude '*/.dropbox'           \
    --exclude '*/volumes/'           \
    --exclude '*/.nx/'           \
    --exclude '*/.npm/'           \
    --exclude '*/.java/'           \
    --exclude '*/.mongodb/'           \
    --exclude '/var/lib'           \
    --exclude '/var/log'           \
                                    \
    ::'{hostname}-{now}'            \
    /etc                            \
    /home                           \
    /root                           \
    /var

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-*' matching is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --glob-archives '{hostname}-*'  \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

borg compact

compact_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup, Prune, and/or Compact finished with warnings"
else
    info "Backup, Prune, and/or Compact finished with errors"
fi

exit ${global_exit}
