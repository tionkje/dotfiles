#!/usr/bin/env bash
# Stubs hyprctl/fzf/notify-send and a fake $HOME with a stowed-style symlink,
# then asserts monitor-resolution.sh round-trips monitors.lua through the lua
# eval/serialize path: update, re-enable, key preservation, insert.
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == -j ]]; then
  cat <<'JSON'
[
  {"name": "eDP-1", "availableModes": ["1920x1080@60.00Hz"]},
  {"name": "DP-3", "availableModes": ["2560x1440@59.95Hz", "2560x1440@74.97Hz", "1920x1080@60.00Hz"]}
]
JSON
else
  printf '%s\n' "$*" >>"${CALLS_LOG:?}"
fi
EOF
cat >"$tmp/fzf" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
echo "${FZF_PICK:?}"
EOF
printf '#!/bin/sh\n' >"$tmp/notify-send"
chmod +x "$tmp/hyprctl" "$tmp/fzf" "$tmp/notify-send"
export PATH="$tmp:$PATH"
export CALLS_LOG="$tmp/calls.log"

# Fake $HOME with monitors.lua as a symlink into a fake stow package
mkdir -p "$tmp/home/.config/hypr" "$tmp/repo"
cat >"$tmp/repo/monitors.lua" <<'EOF'
return {
    { output = "", mode = "preferred", position = "auto-center-up", scale = "auto" },
    { output = "DP-3", mode = "1920x1080@60.00Hz", position = "auto-center-up", scale = 1, disabled = true, transform = 1 },
}
EOF
ln -s "$tmp/repo/monitors.lua" "$tmp/home/.config/hypr/monitors.lua"

mr=$(realpath ../bin/.local/bin/monitor-resolution.sh)
fail=0

check() {
  local desc=$1 pattern=$2
  if ! grep -qF "$pattern" "$tmp/repo/monitors.lua"; then
    printf 'FAIL: %s\n  missing:  %s\n  file:\n%s\n' "$desc" "$pattern" "$(cat "$tmp/repo/monitors.lua")"
    fail=1
  fi
}

# Confirmed pick on existing entry: mode updated, disabled dropped, extra key kept
HOME="$tmp/home" FZF_PICK="2560x1440@74.97Hz" bash -c 'printf "\n" | "$1"' _ "$mr" >/dev/null
check "mode updated" 'output = "DP-3", mode = "2560x1440@74.97Hz"'
check "position/scale kept, extra key kept after known keys" 'position = "auto-center-up", scale = 1, transform = 1'
check "auto stays a quoted string" 'scale = "auto"'
if grep -qF "disabled" "$tmp/repo/monitors.lua"; then
  echo "FAIL: disabled = true should be dropped on re-enable"
  fail=1
fi
if [[ ! -L "$tmp/home/.config/hypr/monitors.lua" ]]; then
  echo "FAIL: symlink was replaced by a regular file"
  fail=1
fi
F="$tmp/repo/monitors.lua" lua -e 'assert(type(dofile(os.getenv("F"))) == "table")' || { echo "FAIL: rewritten file does not parse"; fail=1; }

# Confirmed pick for an output with no entry yet: inserted with defaults
sed -i 's/DP-3/DP-9/g' "$tmp/repo/monitors.lua"
HOME="$tmp/home" FZF_PICK="1920x1080@60.00Hz" bash -c 'printf "\n" | "$1"' _ "$mr" >/dev/null
check "new entry inserted" '{ output = "DP-3", mode = "1920x1080@60.00Hz", position = "auto-center-up", scale = 1 },'

# No confirm (stdin EOF): file untouched, revert dispatched to old resolution
before=$(cat "$tmp/repo/monitors.lua")
HOME="$tmp/home" FZF_PICK="2560x1440@59.95Hz" "$mr" </dev/null >/dev/null
if [[ $before != $(cat "$tmp/repo/monitors.lua") ]]; then
  echo "FAIL: revert path must not touch monitors.lua"
  fail=1
fi
if ! grep -qF "keyword monitor DP-3,1920x1080@60.00Hz,auto-center-up,1" "$CALLS_LOG"; then
  printf 'FAIL: revert should restore old mode\n  calls:\n%s\n' "$(cat "$CALLS_LOG")"
  fail=1
fi

[[ $fail == 0 ]] && echo "OK: all checks passed"
exit "$fail"
