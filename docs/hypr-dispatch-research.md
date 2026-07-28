# Why hypr-dispatch exists: `hyprctl dispatch` differs per config provider

Researched 2026-07-27 against primary sources only: official wiki (wiki.hypr.land, markdown source
in [hyprwm/hyprland-wiki](https://github.com/hyprwm/hyprland-wiki)) and Hyprland source
([hyprwm/Hyprland](https://github.com/hyprwm/Hyprland), `main` + tag `v0.56.0` — the installed
version). Companion doc: `docs/hyprland-config-introspection.md`.

## TL;DR

The lua provider is **upstream Hyprland**, not a fork. Since 0.55 hyprlang is deprecated in favor
of lua, and under the lua provider `hyprctl dispatch <arg>` evaluates `<arg>` as lua
(`hl.dispatch(<arg>)`) instead of hyprlang dispatcher syntax. That behavioral split is documented
on the official wiki and confirmed in Hyprland source. `hypr-dispatch`
(`hypr-common/.local/bin/hypr-dispatch`) exists so scripts shared by both engines
(`hypr-cycle-or-group`, `launch-or-focus`, `monitor-handler.sh`, `presentation-mode.sh`,
`hypridle.conf`, eww, fzl) can keep one calling convention while these dotfiles A/B the two
engines via `hypr-engine` (`bin/.local/bin/hypr-engine`). Since the 2026-07 flip that convention
is the **native lua expression** (`hypr-dispatch 'hl.dsp.focus({ workspace = [[name:edit]] })'`):
lua passes through verbatim, and the script translates *back* to hyprlang only on the legacy
provider. Tested by `tests/hypr-dispatch.test.sh`.

## 1. The lua provider is official upstream

- Wiki [Configuring/Start](https://wiki.hypr.land/Configuring/Start/): "Since Hyprland 0.55,
  hyprlang is deprecated in favor of lua." Config is `~/.config/hypr/hyprland.lua`; old syntax
  lives on the 0.54 wiki pages.
- The `hl.dsp.*` API used by hypr-dispatch is the official lua dispatcher API:
  [Configuring/Basics/Dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
  (wiki source `content/Configuring/Basics/Dispatchers.md`): "Dispatchers return tables … Their
  purpose is to be fed into `hl.bind()` or `hl.dispatch()`." Tables for `hl.dsp.` (incl.
  `focus({workspace|window|monitor})`, `dpms({action?, monitor?})`, `exec_cmd(cmd, rules?)`),
  `hl.dsp.window.` (`cycle_next({next?, tiled?, floating?, window?})`), `hl.dsp.workspace.`
  (`move({workspace?, monitor})`), `hl.dsp.group.` (`next()`, `prev()`).
- Implemented upstream in `src/config/lua/bindings/LuaBindingsDispatchers.cpp`. Not a fork;
  `hypr-lua/.config/hypr/hyprland.lua` is just this repo's config written against that API.

## 2. `hyprctl dispatch` behavior differs per provider — documented + in source

- Wiki [Using hyprctl](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/)
  (source `content/Configuring/Advanced and Cool/Using-hyprctl.md`): "Dispatch is a shorthand for
  `eval 'hl.dispatch(...)'`", example `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'`.
  Also documents `eval`, `repl`, and `reload full-reset` (switch to/from lua/hyprlang).
- Source, tag v0.56.0 (installed): `src/debug/HyprCtl.cpp` `dispatchRequest` (~L1126): if
  `Config::mgr()->type() == Config::CONFIG_LUA` it evaluates
  `return hl.dispatch(<arg>)`, and appends "your syntax might need to be updated" when the arg
  looks like old hyprlang; else (legacy/hyprlang provider) it does the classic
  name-plus-arg lookup in `g_pKeybindManager->m_dispatchers` (~L1142-1157).
- Source, `main` branch: the hyprlang branch is **gone** — `dispatchRequest` returns
  "current config provider doesn't support dispatch" for non-lua (HyprCtl.cpp ~L1143). So the
  plain-passthrough fallback in hypr-dispatch:10 works on 0.56.0 but will stop working on the
  hyprlang provider in a future release.
- `eval` is lua-only in both: "eval is only supported with the lua config manager"
  (HyprCtl.cpp `evalRequest`, v0.56.0 ~L1109). `keyword` is legacy-only: "keyword can't work
  with non-legacy parsers. Use eval." (v0.56.0 `dispatchKeyword`).

## 3. `hyprctl status` / `configProvider`: in source, NOT on the wiki

- `hyprctl status` exists upstream: registered in HyprCtl.cpp
  (`registerCommand({"status", true, statusRequest})`, main ~L1909) →
  `Helpers::SystemInfo::getStatus`, which prints `configProvider: <lua|…>` and `backend:`
  (`src/helpers/SystemInfo.cpp` ~L52/L60, `Config::typeToString(Config::mgr()->type())`).
- **Absent from official docs**: the wiki Using-hyprctl page documents no `status` command and
  never mentions `configProvider` (grep of the wiki repo for `configProvider`: zero hits;
  only source hit is `src/helpers/SystemInfo.cpp`). The probe in hypr-dispatch:9 and
  hypr-engine:16-31 relies on source-level/`hyprctl --help` behavior, not documented API.

## 4. Per-dispatcher notes (script vs primary sources)

- `dpms`: wiki param table (Dispatchers.md ~L22) — `action` = `toggle` (default if no value),
  `enable`/`on`, `disable`/`off`. Source `Internal::tableToggleAction`
  (`src/config/lua/bindings/LuaBindingsInternal.cpp` v0.56.0 L444-452): a **non-table arg
  silently falls back to TOGGLE** — confirms the black-screen incident noted in
  hypr-dispatch:27-28 (`hl.dsp.dpms("on")` toggled instead of enabling). The
  `{ action = "on" }` form the script emits is correct.
- **Bug found — `cyclenext prev` (fixed by the flip)**: the pre-flip script emitted
  `hl.dsp.window.cycle_next({ prev = true })`, but upstream `hlWindowCycleNext` reads only
  `next`/`tiled`/`floating` keys (LuaBindingsDispatchers.cpp v0.56.0 L973-994 and same on main);
  `prev` is silently ignored and `next` defaults to `true`, so "prev" cycled **forward**. The
  wiki table agrees (`cycle_next({ next?, tiled?, floating?, window? })`).
  `hypr-common/.local/bin/hypr-cycle-or-group` now passes the correct
  `hl.dsp.window.cycle_next({ next = false })` natively.
- `workspace`/`focuswindow`/`focusmonitor` → `hl.dsp.focus({workspace|window|monitor})`,
  `moveworkspacetomonitor` → `hl.dsp.workspace.move({workspace, monitor})`,
  `changegroupactive b|f` → `hl.dsp.group.prev()/next()`, `exec` → `hl.dsp.exec_cmd(cmd, rules?)`
  (rules table replaces the old `[monitor X]` prefix): all match the wiki tables above.

## Verdict

Needed: yes, while both engines are in rotation. The provider-dependent `hyprctl dispatch`
semantics are real, upstream, and documented (wiki Using-hyprctl + Dispatchers). Undocumented
parts this repo relies on: `hyprctl status`/`configProvider` (source-only), and the
lua-string-literal quoting constraint (lua `[[ ]]` has no escaping — argument content must not
contain `]`, enforced by the rigid translation regexes). Direction since the 2026-07 flip:
callers speak native lua, the script translates lua→hyprlang only on the legacy provider. End
state once hyprlang is dropped locally: `s/hypr-dispatch/hyprctl dispatch/` in callers and
delete the script — no rewrite needed.
