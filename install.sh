#!/usr/bin/env zsh
# I am using zsh instead of bash.  I was having some troubles using bash with
# arrays.  Didn't want to investigate, so I just did zsh
pushd $DOTFILES
for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g")
do
    echo "stow $folder"
    stow -D $folder
    # --no-folding: always create real dirs + per-file symlinks. Required so systemd
    # follows drop-in dirs like ~/.config/systemd/user/hypridle.service.d/ (systemd
    # does not follow symlinked drop-in directories).
    stow --no-folding $folder
done
popd

