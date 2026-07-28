# Plan: flip hypr-dispatch — lua in, hyprlang out

> For agentic workers: execute task-by-task with superpowers:executing-plans
> or superpowers:subagent-driven-development. Checkboxes track steps.

**Goal:** invert `hypr-common/.local/bin/hypr-dispatch`. Today callers speak
old hyprlang dispatcher syntax and the script translates *to* lua when the
lua provider is active. After the flip, callers speak the native lua
dispatcher API (`hl.dsp.*`) and the script translates *back* to hyprlang only
when the legacy provider is active. End state once hyprlang is dropped:
replace `hypr-dispatch '<lua>'` with `hyprctl dispatch '<lua>'` in callers
and delete the script — no rewrite needed.

**New calling convention:** exactly one argument, the lua expression:

```
hypr-dispatch 'hl.dsp.focus({ workspace = [[name:edit]] })'
```

Constraints carried over from `docs/hypr-dispatch-research.md`:
- lua `[[ ]]` long strings have no escaping → argument content must not
  contain `]]` (now also no lone `]`, see translation regex). All current
  args are workspace names / monitor names / window addresses / one alacritty
  command — none contain `]`.
- `cyclenext prev` bug (research §4): the lua form must be
  `hl.dsp.window.cycle_next({ next = false })` — `{ prev = true }` is
  silently ignored upstream. The flip fixes this in `hypr-cycle-or-group`.
- Detection stays `hyprctl status | grep 'configProvider: lua'`
  (undocumented but source-confirmed, research §3).

Lua expression ↔ hyprlang translation table (all forms these dotfiles use):

| lua (input) | hyprlang (output on legacy provider) |
|---|---|
| `hl.dsp.focus({ workspace = [[X]] })` | `workspace X` |
| `hl.dsp.focus({ window = [[X]] })` | `focuswindow X` |
| `hl.dsp.focus({ monitor = [[X]] })` | `focusmonitor X` |
| `hl.dsp.workspace.move({ workspace = [[X]], monitor = [[Y]] })` | `moveworkspacetomonitor X Y` |
| `hl.dsp.dpms({ action = [[X]] })` | `dpms X` |
| `hl.dsp.window.cycle_next()` | `cyclenext` |
| `hl.dsp.window.cycle_next({ next = false })` | `cyclenext prev` |
| `hl.dsp.group.next()` | `changegroupactive f` |
| `hl.dsp.group.prev()` | `changegroupactive b` |
| `hl.dsp.exec_cmd([[CMD]])` | `exec CMD` |
| `hl.dsp.exec_cmd([[CMD]], { monitor = [[M]] })` | `exec [monitor M] CMD` |

Matching is rigid (exact spacing as written above); anything else errors
loudly (stderr + `notify-send -u critical` + exit 2), same failure mode as
today's unknown-dispatcher branch.

## 1. Rewrite hypr-dispatch, test-first

Files: create `tests/hypr-dispatch.test.sh`, rewrite
`hypr-common/.local/bin/hypr-dispatch`.

- [x] Write `tests/hypr-dispatch.test.sh` (repo root `tests/` dir is new; it
      must NOT live inside a stow package or it gets symlinked into `$HOME`):

```bash
#!/usr/bin/env bash
# Stubs hyprctl/notify-send on PATH and asserts what hypr-dispatch execs.
set -euo pipefail
cd "$(dirname "$0")"
stub=$(mktemp -d)
trap 'rm -rf "$stub"' EXIT

cat >"$stub/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == status ]]; then
  echo "configProvider: ${HYPRCTL_PROVIDER}"
else
  printf '%s\n' "$@"
fi
EOF
printf '#!/bin/sh\n' >"$stub/notify-send"
chmod +x "$stub/hyprctl" "$stub/notify-send"
export PATH="$stub:$PATH"

hd=../hypr-common/.local/bin/hypr-dispatch
fail=0

check() {
  local desc=$1 provider=$2 input=$3 expected=$4 got
  got=$(HYPRCTL_PROVIDER=$provider "$hd" "$input")
  if [[ $got != "$expected" ]]; then
    printf 'FAIL: %s\n  got:      %q\n  expected: %q\n' "$desc" "$got" "$expected"
    fail=1
  fi
}

# lua provider: verbatim passthrough
check "passthrough" lua \
  'hl.dsp.focus({ workspace = [[name:edit]] })' \
  $'dispatch\nhl.dsp.focus({ workspace = [[name:edit]] })'

# legacy provider: translate back to hyprlang
check "workspace" legacy \
  'hl.dsp.focus({ workspace = [[name:edit]] })' \
  $'dispatch\nworkspace\nname:edit'
check "focuswindow" legacy \
  'hl.dsp.focus({ window = [[address:0x55dd75000000]] })' \
  $'dispatch\nfocuswindow\naddress:0x55dd75000000'
check "focusmonitor" legacy \
  'hl.dsp.focus({ monitor = [[eDP-1]] })' \
  $'dispatch\nfocusmonitor\neDP-1'
check "moveworkspacetomonitor" legacy \
  'hl.dsp.workspace.move({ workspace = [[name:work]], monitor = [[HDMI-A-1]] })' \
  $'dispatch\nmoveworkspacetomonitor\nname:work\nHDMI-A-1'
check "dpms" legacy \
  'hl.dsp.dpms({ action = [[on]] })' \
  $'dispatch\ndpms\non'
check "cyclenext" legacy \
  'hl.dsp.window.cycle_next()' \
  $'dispatch\ncyclenext'
check "cyclenext prev" legacy \
  'hl.dsp.window.cycle_next({ next = false })' \
  $'dispatch\ncyclenext\nprev'
check "changegroupactive f" legacy \
  'hl.dsp.group.next()' \
  $'dispatch\nchangegroupactive\nf'
check "changegroupactive b" legacy \
  'hl.dsp.group.prev()' \
  $'dispatch\nchangegroupactive\nb'
check "exec" legacy \
  "hl.dsp.exec_cmd([[alacritty -o 'window.startup_mode=\"Windowed\"' -e fzl]])" \
  $'dispatch\nexec\nalacritty -o \'window.startup_mode="Windowed"\' -e fzl'
check "exec with monitor" legacy \
  'hl.dsp.exec_cmd([[foot -e btop]], { monitor = [[HDMI-A-1]] })' \
  $'dispatch\nexec\n[monitor HDMI-A-1] foot -e btop'

# unknown form: loud exit 2, nothing dispatched
if out=$(HYPRCTL_PROVIDER=legacy "$hd" 'hl.dsp.bogus()' 2>&1); then
  echo "FAIL: unknown form should exit 2, got: $out"
  fail=1
fi

[[ $fail == 0 ]] && echo "OK: all checks passed"
exit "$fail"
```

- [x] `chmod +x tests/hypr-dispatch.test.sh`, run it — expect FAILs on every
      legacy check and the passthrough check (current script still translates
      the other direction), confirming the test bites
- [x] Rewrite `hypr-common/.local/bin/hypr-dispatch`:

```bash
#!/usr/bin/env bash
# hyprctl dispatch that works under both config providers. Callers pass the
# native lua dispatcher expression, e.g.:
#   hypr-dispatch 'hl.dsp.focus({ workspace = [[name:edit]] })'
# Under the lua provider (hypr-engine lua) it passes straight through; under
# the legacy hyprlang provider the expressions these dotfiles use are
# translated back to old dispatcher syntax. Once hyprlang is dropped, replace
# callers with plain `hyprctl dispatch` and delete this script.
source "$HOME/.local/bin/err-notify"
set -euo pipefail

if hyprctl status | grep -q 'configProvider: lua'; then
  exec hyprctl dispatch "$1"
fi

# ponytail: rigid match on the exact formatting the callers use (single
# spaces, [[ ]] strings containing no ']'); anything else errors loudly below
lit='\[\[([^]]*)\]\]'
re_ws="^hl\.dsp\.focus\(\{ workspace = $lit \}\)$"
re_win="^hl\.dsp\.focus\(\{ window = $lit \}\)$"
re_mon="^hl\.dsp\.focus\(\{ monitor = $lit \}\)$"
re_move="^hl\.dsp\.workspace\.move\(\{ workspace = $lit, monitor = $lit \}\)$"
re_dpms="^hl\.dsp\.dpms\(\{ action = $lit \}\)$"
re_exec="^hl\.dsp\.exec_cmd\($lit\)$"
re_exec_mon="^hl\.dsp\.exec_cmd\($lit, \{ monitor = $lit \}\)$"

if   [[ $1 =~ $re_ws ]];   then set -- workspace "${BASH_REMATCH[1]}"
elif [[ $1 =~ $re_win ]];  then set -- focuswindow "${BASH_REMATCH[1]}"
elif [[ $1 =~ $re_mon ]];  then set -- focusmonitor "${BASH_REMATCH[1]}"
elif [[ $1 =~ $re_move ]]; then set -- moveworkspacetomonitor "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
elif [[ $1 =~ $re_dpms ]]; then set -- dpms "${BASH_REMATCH[1]}"
elif [[ $1 == 'hl.dsp.window.cycle_next()' ]]; then set -- cyclenext
elif [[ $1 == 'hl.dsp.window.cycle_next({ next = false })' ]]; then set -- cyclenext prev
elif [[ $1 == 'hl.dsp.group.next()' ]]; then set -- changegroupactive f
elif [[ $1 == 'hl.dsp.group.prev()' ]]; then set -- changegroupactive b
elif [[ $1 =~ $re_exec ]]; then set -- exec "${BASH_REMATCH[1]}"
elif [[ $1 =~ $re_exec_mon ]]; then set -- exec "[monitor ${BASH_REMATCH[2]}] ${BASH_REMATCH[1]}"
else
  echo "hypr-dispatch: no hyprlang translation for: $1" >&2
  notify-send -u critical "hypr-dispatch" "no hyprlang translation for: $1"
  exit 2
fi

hyprctl dispatch "$@"
```

- [x] Run `tests/hypr-dispatch.test.sh` — expect `OK: all checks passed`
- [x] Commit: `git add tests/hypr-dispatch.test.sh hypr-common/.local/bin/hypr-dispatch && git commit -m "flip hypr-dispatch: lua in, hyprlang out on legacy provider"`

Note: callers are NOT migrated yet — old-syntax calls now hit the loud error
branch on both providers. That is fine within this branch; task 2 follows
immediately. Don't stop between tasks 1 and 2 on a live session.

## 2. Migrate all callers to lua syntax

Files (every non-doc `hypr-dispatch` call site, from
`rg -n hypr-dispatch -g '!docs/*'`):

- [x] `hypr-common/.config/hypr/monitor-handler.sh:10-20` — 9 lines:

```bash
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:presentation]], monitor = [[$monitor]] })"
```
```bash
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:work]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:edit]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:read]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:talk]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:youtube]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:incognito]], monitor = [[$monitor]] })"
```
```bash
    hypr-dispatch 'hl.dsp.workspace.move({ workspace = [[name:spotify]], monitor = [[eDP-1]] })'
    hypr-dispatch 'hl.dsp.workspace.move({ workspace = [[name:meet]], monitor = [[eDP-1]] })'
```

- [x] `hypr-common/.config/eww/eww.yuck:95`:

```lisp
    :onclick {"hypr-dispatch 'hl.dsp.focus({ window = [[address:" + w.address + "]] })' && eww close workspace-overview workspace-overview-backdrop"}
```

- [x] `hypr-common/.local/bin/launch-or-focus:23,26`:

```bash
  hypr-dispatch "hl.dsp.focus({ window = [[address:$WINDOW_ADDRESS]] })"
```
```bash
    hypr-dispatch "hl.dsp.focus({ workspace = [[name:$WORKSPACE]] })"
```

- [x] `hypr-common/.local/bin/hypr-cycle-or-group:7-18` — the case now
      builds full lua expressions (this also fixes the research-§4 prev bug,
      which was in this caller's lua path):

```bash
case "$dir" in
  f) cycle='hl.dsp.window.cycle_next()';                 group='hl.dsp.group.next()' ;;
  b) cycle='hl.dsp.window.cycle_next({ next = false })'; group='hl.dsp.group.prev()' ;;
  *) echo "[hypr-cycle-or-group] usage: $0 [f|b]" >&2; exit 2 ;;
esac

before=$(hyprctl activewindow -j | jq -r '.address // empty')
hypr-dispatch "$cycle" >/dev/null
after=$(hyprctl activewindow -j | jq -r '.address // empty')

if [[ "$before" == "$after" ]]; then
  hypr-dispatch "$group" >/dev/null
fi
```

- [x] `bin/.local/bin/fzl:19` (bash `\"` inside double quotes yields the same
      literal `"` as before; lua content is unchanged):

```bash
  hypr-dispatch "hl.dsp.exec_cmd([[alacritty --class fzl-launcher -o 'window.startup_mode=\"Windowed\"' -o 'window.opacity=0.9' -e fzl]], { monitor = [[$MON]] })"
```

- [x] `bin/.local/bin/fzl:94`:

```bash
  hypr-dispatch 'hl.dsp.focus({ workspace = [[name:edit]] })'
```

- [x] `hypr/.config/hypr/presentation-mode.sh:18,21,22,31,34,35,37` — 7 lines:

```bash
    hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:$ws]], monitor = [[$EXT]] })"
```
```bash
  hypr-dispatch "hl.dsp.focus({ monitor = [[$EXT]] })"
  hypr-dispatch 'hl.dsp.focus({ workspace = [[name:work]] })'
```
```bash
    hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:$ws]], monitor = [[$LAPTOP]] })"
```
```bash
  hypr-dispatch "hl.dsp.focus({ monitor = [[$EXT]] })"
  hypr-dispatch 'hl.dsp.focus({ workspace = [[name:presentation]] })'
```
```bash
  hypr-dispatch "hl.dsp.focus({ monitor = [[$LAPTOP]] })"
```

- [x] `hypr/.config/hypr/hypridle.conf:20,21,44,45` (hypridle runs these via
      shell — the existing `&&` chains prove it — so single quotes are safe;
      keep the existing trailing `#` comments, hyprlang strips them):

```ini
    before_sleep_cmd = loginctl lock-session && ~/.local/bin/hypr-dispatch 'hl.dsp.dpms({ action = [[on]] })'    # lock before suspend.
    after_sleep_cmd = ~/.local/bin/hypr-dispatch 'hl.dsp.dpms({ action = [[on]] })'  # to avoid having to press a key twice to turn on the display.
```
```ini
    on-timeout = ~/.local/bin/hypr-dispatch 'hl.dsp.dpms({ action = [[off]] })'                            # screen off when timeout has passed
    on-resume = ~/.local/bin/hypr-dispatch 'hl.dsp.dpms({ action = [[on]] })' && brightnessctl -r          # screen on when activity is detected after timeout has fired.
```

- [x] Verify nothing was missed: `rg -n "hypr-dispatch (workspace|focuswindow|focusmonitor|moveworkspacetomonitor|dpms|cyclenext|changegroupactive|exec) " -g '!docs/*'` → zero hits
- [x] `bash -n` every touched shell file
- [x] Run `tests/hypr-dispatch.test.sh` again — still `OK`
- [x] Commit: `git add -u && git commit -m "migrate hypr-dispatch callers to lua syntax"`

## 3. Reload daemons + live smoke test

Stowed symlinks make script edits live immediately, but eww and hypridle
cache their config at startup:

- [x] `eww reload`
- [x] `systemctl --user restart hypridle` (or however hypridle is managed —
      check `systemctl --user status hypridle` first)
- [x] `hyprctl status | grep configProvider` — note which provider is live
- [ ] Smoke test on the live session:
      `hypr-dispatch 'hl.dsp.focus({ workspace = [[name:edit]] })'` switches
      workspace; `hypr-cycle-or-group f` then `b` cycles both directions
      (b must actually go backward now); `launch-or-focus` on a running app
      focuses it; fzl `--launch` opens on the right monitor
- [ ] `hypr-dispatch 'hl.dsp.dpms({ action = [[off]] })'`, wiggle mouse /
      press key, screen comes back (guards the hypridle path)
- [ ] If both engines are still in rotation, repeat the smoke test once after
      the next `hypr-engine` swap to cover the other provider
- [x] Update `docs/hypr-dispatch-research.md` TL;DR + Verdict: direction is
      now lua→hyprlang; the §4 prev bug is fixed; end state is
      s/hypr-dispatch/hyprctl dispatch/ + delete script
- [x] Commit: `git add -u && git commit -m "hypr-dispatch flip: docs + smoke tested"`
