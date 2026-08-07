#!/usr/bin/env bash
set -euo pipefail
trap 'notify-send -u critical "Error: $(basename "$0")" "Line $LINENO failed (exit $?)"' ERR

# killall returns non-zero when no waybar is running (e.g. first boot) — expected.
killall waybar || true

# style.css @imports this; create empty (sleep-inhibit off) if missing so the import never dangles.
touch "$HOME/.config/waybar/sleep-inhibit-state.css"

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/waybar.log"
mkdir -p "$(dirname "$log_file")"
waybar >>"$log_file" 2>&1 &
