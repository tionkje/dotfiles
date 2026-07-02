# Plan: create the hypr-lua package and clean up the draft

`hypr-engine lua` and install.sh both stow `$DOTFILES/hypr-lua`, but the
package doesn't exist — the lua config only lives at
`hypr/.config/hypr/hyprland.lua.draft`. Until this is done, `hypr-engine lua`
fails at `stow hypr-lua`.

## 1. Create the hypr-lua package

Mirror hypr-conf's layout (the engine packages are mutually exclusive and
must each carry the shared files, since hypr-engine swaps whole packages):

```
hypr-lua/
  .config/hypr/hyprland.lua        <- from hypr/.config/hypr/hyprland.lua.draft
  .config/hypr/monitor-handler.sh
  .config/eww/eww.yuck
  .local/bin/launch-or-focus
  .local/bin/hypr-cycle-or-group
```

- [ ] `git mv hypr/.config/hypr/hyprland.lua.draft hypr-lua/.config/hypr/hyprland.lua`
- [ ] Copy the 4 shared files from hypr-conf (they're identical for both
      engines today; they only live per-package because the engines swap
      atomically — consider a shared `hypr-common` package later if they
      start drifting)
- [ ] Apply the gap fixes from `plan-hypr-lua-gaps.md` to the new
      `hyprland.lua` before first activation

## 2. Clean up draft leftovers

- [ ] Removing the draft from the `hypr` package orphans the
      `~/.config/hypr/hyprland.lua.draft` symlink — `stow -D hypr` before
      the move, restow after (install.sh already does this)
- [ ] Drop the draft-activation header comment ("rename this to
      hyprland.lua") — activation is now `hypr-engine lua`

## 3. First activation + verification

- [ ] `hypr-engine lua`, then restart Hyprland (`hyprctl dispatch exit`) —
      engine selection happens at startup, not on reload
- [ ] Work through the TODO checklist in `plan-hypr-lua-gaps.md` §5 with
      `hyprctl` (rule effects, fullscreen arg, monitor fallback, mode string)
- [ ] Confirm `hyprctl monitors`, workspaces on the right outputs, groups on
      spotify/read, eww sidebar blur, hypridle running exactly once (via the
      systemd target, not double-started)
- [ ] `hypr-engine conf` round-trip still works (rollback path)
