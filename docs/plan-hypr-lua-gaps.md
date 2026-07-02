# Plan: close functional gaps in the hyprland.lua conversion

Gaps found comparing `hypr/.config/hypr/hyprland.lua.draft` against
`hypr-conf/.config/hypr/hyprland.conf` (Hyprland 0.55.4, lua engine).
The port is otherwise faithful: all binds, 9/9 workspace rules, window/layer
rules, animations, groupbar/input/device settings match.

## 1. Restore systemd session target startup

`hyprland.conf:77` runs:

```
dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP && systemctl --user start hyprland-session.target
```

The draft omits it and launches `hypridle` directly instead (draft line ~62).
This breaks every `WantedBy=graphical-session.target` user service — the
`hypridle.service.d` drop-in exists precisely for this path — and risks a
double hypridle (direct exec + target).

- [ ] Add the dbus/systemctl line to the `hyprland.start` handler
- [ ] Remove the direct `hl.exec_cmd("hypridle")`

## 2. Restore Chrome/Brave notification popup rules

`hyprland.conf:104-106`: float + pin + no_initial_focus on
`match:class ^([Gg]oogle-chrome|[Cc]hromium|[Bb]rave).*$` +
`match:initial_title .*[Nn]otification.*`. Missing from the draft entirely.

- [ ] Port as `hl.window_rule` calls (lua rule effect key is likely
      `no_focus` per `/usr/share/hypr/hyprland.lua` example — the conf used
      `no_initial_focus`; verify which one the lua engine expects)

## 3. Restore per-machine monitor config

The conf `source`s `~/.config/hypr/monitors.conf` — a local, non-symlinked,
machine-specific file. The draft hardcodes the monitor table, so a second
machine can no longer override.

- [ ] Replace the hardcoded table with a local include, e.g.
      `pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitors.lua")`
      falling back to a sane default `hl.monitor({ output = "", ... })`
- [ ] Create `~/.config/hypr/monitors.lua` on this machine from the current
      table (values already match the live monitors.conf)

## 4. Engine-switch gap in hypr-engine

The old script created the new `hyprland.*` symlink *before* removing the
other one, with a comment that Hyprland regenerates a default stub when its
config path goes missing. The stow-based rewrite does `stow -D` then `stow`,
leaving a window with no config file; if the stub gets written in that
window, the restow conflicts and fails.

- [ ] Verify whether Hyprland 0.55 still writes a stub on missing config
- [ ] If yes: stow the new package first, `stow -D` the old one after
      (order is safe — the packages share no filenames)

## 5. Verify the draft's open TODOs after activation

The stub (`/usr/share/hypr/stubs/hl.meta.lua`) genuinely doesn't answer
these; check with `hyprctl` once running on lua:

- [ ] `fullscreen_state = "0 2"` as a window rule effect (fake fullscreen
      for brave-youtube)
- [ ] `group = "set always"` / `group = "deny"` rule effects
- [ ] `hl.dsp.window.fullscreen(1)` arg shape (old `fullscreen, 1` = maximize)
- [ ] workspace rule `monitor` with comma-separated fallback — stub types it
      as a single string; most likely to silently misbehave, but
      monitor-handler.sh reassigns at runtime anyway
- [ ] `2560x1440@59.95Hz` mode string (trailing `Hz` accepted?)
