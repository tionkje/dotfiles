# Plan: create the hypr-lua package and clean up the draft

`hypr-engine lua` and install.sh both stow `$DOTFILES/hypr-lua`, but the
package doesn't exist — the lua config only lives at
`hypr/.config/hypr/hyprland.lua.draft`. Until this is done, `hypr-engine lua`
fails at `stow hypr-lua`.

## 0. Create hypr-common first (prerequisite, not "later")

The original layout gave each engine package copies of the 4 shared files.
That breaks the engine-swap ordering fix in `plan-hypr-lua-gaps.md` §4 (stow
refuses to stow over another package's symlinks), and it already breaks
today's rollback: once hypr-lua exists with the copies, `hypr-engine conf`
would conflict on them. Shared files go in one always-stowed package instead:

```
hypr-common/
  .config/hypr/monitor-handler.sh   <- git mv from hypr-conf
  .config/eww/eww.yuck              <- git mv from hypr-conf
  .local/bin/launch-or-focus        <- git mv from hypr-conf
  .local/bin/hypr-cycle-or-group    <- git mv from hypr-conf
```

- [ ] `git mv` the 4 files out of hypr-conf into hypr-common
- [ ] Add `hypr-common` to STOW_FOLDERS in `archlinux.sh:3`
- [ ] Restow: `stow -D hypr-conf` (removes the old symlinks), stow
      hypr-common, then `hypr-engine conf` — do this in one go; eww and the
      bin scripts are unlinked in between (transient, seconds)
- [ ] Bonus: eww/scripts no longer flicker out of existence on engine swaps

## 1. Create the hypr-lua package

Engine packages now carry only their config file:

```
hypr-lua/
  .config/hypr/hyprland.lua        <- from hypr/.config/hypr/hyprland.lua.draft
```

- [ ] `git mv hypr/.config/hypr/hyprland.lua.draft hypr-lua/.config/hypr/hyprland.lua`
- [ ] Apply the gap fixes from `plan-hypr-lua-gaps.md` to the new
      `hyprland.lua` before first activation
- [ ] Apply the §4 ordering fix to hypr-engine (stow new engine first,
      `stow -D` old after — safe now that the packages are disjoint)

## 2. Clean up draft leftovers

- [ ] FIRST: `git rm hypr/.config/hypr/monitors.conf` (keep the local file) —
      the live `~/.config/hypr/monitors.conf` is a regular file, not a
      symlink, so restowing hypr conflicts on it and stow aborts the whole
      package *after* `stow -D hypr` already unlinked hypridle.conf and
      hyprlock.conf. Machine-local per `plan-hypr-lua-gaps.md` §3 anyway
- [ ] Removing the draft from the `hypr` package orphans the
      `~/.config/hypr/hyprland.lua.draft` symlink — `stow -D hypr` before
      the move, restow after (install.sh already does this). Note: this
      briefly unlinks hypridle.conf/hyprlock.conf too; hypridle has
      `Restart=always`/10s so worst case one restart cycle — just don't lock
      the screen mid-move
- [ ] Drop the draft-activation header comment ("rename this to
      hyprland.lua") — activation is now `hypr-engine lua`

## 3. First activation + verification

- [ ] Gate: `Hyprland --verify-config --config` on the package file *before*
      stowing, and on `~/.config/hypr/hyprland.lua` *after* stowing (see
      `plan-hypr-lua-gaps.md` §0) — only restart on `config ok`
- [ ] `hypr-engine lua`, then restart Hyprland (`hyprctl dispatch exit`) at a
      moment a relogin is affordable — engine selection happens at startup,
      not on reload (unverified; the pre-stow verify gate covers the case
      where a live autoreload picks up the .lua early)
- [ ] Work through the runtime checklist in `plan-hypr-lua-gaps.md` §5 with
      `hyprctl` (parse-level items are already verified via --verify-config)
- [ ] Confirm `hyprctl monitors`, workspaces on the right outputs, groups on
      spotify/read, eww sidebar blur, hypridle running exactly once (via the
      systemd target, not double-started)
- [ ] `hypr-engine conf` round-trip still works (rollback path — fixed by §0,
      broken before it)
- [ ] Rollback if the session won't come up: TTY (Ctrl+Alt+F3),
      `hypr-engine conf`, log back in
