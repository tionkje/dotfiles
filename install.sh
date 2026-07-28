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

# hypr-engine manages the hypr config: it always ensures the hypr-conf fallback
# (non-destructive stow, kept out of the STOW_FOLDERS loop so a reinstall never
# unlinks the live-watched hyprland.conf) and toggles the hypr-lua overlay,
# which Hyprland prefers when present. Re-assert the active engine across
# reinstalls; default to conf on a fresh machine.
current_engine=$($DOTFILES/bin/.local/bin/hypr-engine status)
if [[ $current_engine == none ]]; then
    current_engine=conf
fi
echo "hypr-engine $current_engine"
$DOTFILES/bin/.local/bin/hypr-engine $current_engine

popd

