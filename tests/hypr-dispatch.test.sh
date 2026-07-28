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
