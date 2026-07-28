# Inspecting loaded config in a running Hyprland instance

Researched 2026-07-25 against primary sources only: official wiki (wiki.hypr.land, markdown source in
[hyprwm/hyprland-wiki](https://github.com/hyprwm/hyprland-wiki)) and Hyprland source
([hyprwm/Hyprland](https://github.com/hyprwm/Hyprland)). Cross-checked live on this machine
(Hyprland **0.56.0**, `hyprctl status` → `configProvider: hyprlang`, i.e. still on the hyprlang
provider, not lua).

Context: since Hyprland **0.55 hyprlang is deprecated in favor of Lua** (`hyprland.lua`). Old syntax
docs live at the versioned wiki (`https://wiki.hypr.land/0.54.0/`).
Source: [Configuring/Start](https://wiki.hypr.land/Configuring/Start/) ("Since Hyprland 0.55,
hyprlang is deprecated in favor of lua").

## 1. hyprctl commands for live config inspection

All from [Using hyprctl](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/)
(hyprlang-era version: [0.54.0 Using hyprctl](https://wiki.hypr.land/0.54.0/Configuring/Using-hyprctl/))
and verified in [src/debug/HyprCtl.cpp](https://github.com/hyprwm/Hyprland/blob/main/src/debug/HyprCtl.cpp)
(command registrations ~L1889-1927). Add `-j` for JSON on any info command.

### getoption
`hyprctl getoption <section>:<option>` — "gets the config option status (values)".
- hyprlang provider uses `:` separators (`general:border_size`, `input:touchpad:disable_while_typing`);
  the lua-era wiki writes `.` separators (`general.border_size`). Verified live on 0.56/hyprlang:
  colon works, dot returns `no such option`.
- Output format (from `dispatchGetOption`, HyprCtl.cpp ~L1532):
  ```
  int: 2
  set: true
  ```
  `set` = whether the value was set by the user (vs still default).
  JSON: `{"option": "general:border_size", "int": 2, "set": true }`.
- Unknown option → `no such option`.

### systeminfo
`hyprctl systeminfo` — version, system, monitors, libs, GPU. **Does NOT include config by default.**
With the `-c` flag (`hyprctl systeminfo -c`) it appends the **full loaded config of every file**,
each prefixed `Config File: /path/to/file: Read Succeeded`, between `======Config-Start======` /
`======Config-End========` markers. This is the way to list all sourced files from a running
instance. Verified live (showed `hyprland.conf` + the `source=`d `monitors.conf`) and in source:
`systemInfoRequest` appends `Config::mgr()->getConfigString()` when the `c` request flag is set
(HyprCtl.cpp ~L1096-1105, flag parsing ~L1975).

### configerrors
`hyprctl configerrors` — "lists all current config parsing errors". Empty output = clean config.
Source: `configErrorsRequest` returns `Config::mgr()->getErrors()` (HyprCtl.cpp ~L724).

### descriptions
`hyprctl descriptions` — "returns a JSON with all config options, their descriptions and types."
Verified live: per option it includes `name`, `description`, `default`, **`current`** (live value),
`min`, `max` — so it doubles as a full dump of current option values.

### Other info commands that reflect loaded config
- `hyprctl binds` — all registered binds (as parsed from config + runtime-added).
- `hyprctl monitors` (`monitors all` incl. inactive) — applied monitor config.
- `hyprctl workspacerules` — "gets the list of defined workspace rules".
- `hyprctl animations` — currently configured animations and beziers.
- `hyprctl layouts`, `hyprctl devices`, `hyprctl workspaces`, `hyprctl clients`.
- `hyprctl status` — internal status incl. `configProvider: hyprlang|lua` and backend
  (in `hyprctl --help` and HyprCtl.cpp `statusRequest`; not yet on the wiki info list).
- `hyprctl instances` + `-i <id>` flag — inspect a specific running instance.
- `hyprctl rollinglog [-f]` — tail Hyprland log (config reload lines show up here).

## 2. Which config file(s) are loaded

- hyprlang era (≤0.54, and 0.55+ with hyprlang provider): `$XDG_CONFIG_HOME/hypr/hyprland.conf`
  (usually `~/.config/hypr/hyprland.conf`). Lua era (0.55+): `$XDG_CONFIG_HOME/hypr/hyprland.lua`.
  Override with `--config` / `-c` argument.
  Sources: [0.54 Start](https://wiki.hypr.land/0.54.0/Configuring/Start/),
  [current Start](https://wiki.hypr.land/Configuring/Start/).
- Multi-file: hyprlang uses `source = ~/.config/hypr/myColors.conf` (globbing supported:
  `source = ~/.config/hypr/custom/*`) — [0.54 Keywords](https://wiki.hypr.land/0.54.0/Configuring/Keywords/).
  Lua uses `require("dir/file")` with wildcards/absolute paths; each `require()` is an isolated
  scope so an error in one file doesn't kill the others —
  [current Start](https://wiki.hypr.land/Configuring/Start/).
- **Listing all sourced files from a running instance: `hyprctl systeminfo -c`** (see above). No
  dedicated "list config files" command exists.

## 3. Reload behavior

- "The config is reloaded the moment you save it. However, you can use `hyprctl reload` to reload
  the config manually." — both wiki eras ([Start](https://wiki.hypr.land/Configuring/Start/)).
- `misc:disable_autoreload` — "If true, the config will not reload automatically on save, and
  instead needs to be reloaded with `hyprctl reload`. Might save on battery." Default `false`.
  [Variables](https://wiki.hypr.land/Configuring/Basics/Variables/) (misc section).
- `hyprctl reload config-only` — skip monitor reload (from `hyprctl --help`, verified 0.56).
- `hyprctl reload full-reset` (0.55+) — recreates the whole config context, allows switching
  to/from lua/hyprlang; "should not be used unless really necessary."
  [Using hyprctl](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/).

## 4. Runtime-set values (`hyprctl keyword`)

- hyprlang: `hyprctl keyword general:border_size 10` sets an option dynamically; returns `ok`.
  [0.54 Using hyprctl](https://wiki.hypr.land/0.54.0/Configuring/Using-hyprctl/).
- **Yes, keyword-set values show up in `getoption`** — verified live: after
  `hyprctl keyword general:border_size 2`, `getoption general:border_size` → `int: 2, set: true`.
- Not persistent: `hyprctl reload` re-parses the files and the runtime value is lost (verified:
  value reverted to file value after reload).
- Lua era note: `keyword` is absent from the current (lua) wiki command list and from main-branch
  `HyprCtl.cpp` registrations; runtime changes go through `hyprctl eval` / `hyprctl repl`
  (`hl.config({...})`) instead. On 0.56 with hyprlang provider, `keyword` still exists and works.

## 5. Newer introspection features (2025-2026)

- **Lua config** (0.55+): `hyprctl eval '<lua>'` executes code in the live config context;
  `hyprctl repl` gives an interactive Lua REPL to explore state (`hl.get_windows()`,
  `hl.get_active_window().class`, ...). The wiki explicitly recommends the REPL for exploring the
  API and Lua state. [Using hyprctl](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/).
- `hyprctl descriptions` includes `current` values per option (full live dump).
- `hyprctl status` reports which config provider is active (`hyprlang` vs `lua`).
- Config error handling (lua era): syntax errors block reload + pop an error; runtime errors pop
  notifications; emergency keybinds (SUPER+Q/R/M) are provided when the config dies early.
  [Start – Error behavior](https://wiki.hypr.land/Configuring/Start/).
- `hyprctl seterror` note: the error bar resets on config reload — a reload also clears the
  on-screen config-error banner once errors are fixed.

## Quick reference

```sh
hyprctl status                     # config provider (hyprlang/lua), backend
hyprctl systeminfo -c              # full loaded config, ALL sourced files with paths
hyprctl getoption general:border_size   # one option: value + set-by-user (use . on lua provider)
hyprctl -j descriptions            # every option: description, default, CURRENT value
hyprctl configerrors               # parse errors (empty = clean)
hyprctl binds / monitors / workspacerules / animations   # applied config per domain
hyprctl reload [config-only]       # manual reload
hyprctl keyword sect:opt val       # runtime set (hyprlang; visible in getoption, lost on reload)
hyprctl repl                       # lua era: explore live config/state interactively
```
