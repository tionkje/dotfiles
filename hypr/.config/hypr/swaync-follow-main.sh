#!/bin/bash
set -euo pipefail
trap 'notify-send -u critical "Error: $(basename "$0")" "Line $LINENO failed (exit $?)"' ERR

# Point swaync notifications + control center at whichever monitor currently
# hosts the `work` workspace. That single rule covers normal mode, presentation
# mode, and laptop-only — assign_workspaces and presentation-mode.sh both
# move `work` to the right monitor, so following it adapts automatically.

# Swaync not running -> nothing to do (not an error).
pgrep -x swaync >/dev/null || exit 0

main=$(hyprctl -j workspaces | jq -r '.[] | select(.name=="work") | .monitor')
if [[ -z "$main" || "$main" == "null" ]]; then
  main=$(hyprctl -j monitors | jq -r '.[] | select(.focused == true) | .name')
fi

swaync-client --change-noti-monitor "$main"
swaync-client --change-cc-monitor "$main"
