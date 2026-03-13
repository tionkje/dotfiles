#!/usr/bin/env bash

set -euo pipefail

MONITORS_CONF="$HOME/.config/hypr/monitors.conf"
LAPTOP="eDP-1"

# Find external monitor
EXT=$(hyprctl -j monitors | jq -r ".[] | select(.name != \"$LAPTOP\") | .name" | head -1)

if [[ -z "$EXT" ]]; then
  echo "No external monitor detected"
  exit 1
fi

# Read current position and scale from monitors.conf for this monitor
current_line=$(grep "^monitor=${EXT}," "$MONITORS_CONF" 2>/dev/null || true)
if [[ -n "$current_line" ]]; then
  current_pos=$(echo "$current_line" | cut -d',' -f3)
  current_scale=$(echo "$current_line" | cut -d',' -f4)
  current_res=$(echo "$current_line" | cut -d',' -f2)
else
  current_pos="auto"
  current_scale="1"
  current_res="unknown"
fi

# Query available modes: keep highest frequency per resolution, sort highest resolution first
modes=$(hyprctl -j monitors | jq -r ".[] | select(.name == \"$EXT\") | .availableModes[]" \
  | sort -t'@' -k2,2rn \
  | awk -F'@' '!seen[$1]++' \
  | awk -F'[x@]' '{printf "%010d %010d %s\n", $1, $2, $0}' \
  | sort -rn \
  | awk '{print $3}')

# Find line number of current resolution for fzf cursor position
current_idx=$(echo "$modes" | grep -n "^${current_res}$" | head -1 | cut -d: -f1)
fzf_pos=()
if [[ -n "$current_idx" ]]; then
  fzf_pos=(--bind "start:pos($current_idx)")
fi

# Show fzf picker
selected=$(echo "$modes" \
  | fzf --no-info --prompt "resolution ($EXT) > " \
    --header "current: $current_res" "${fzf_pos[@]}") || exit 0

# Save previous resolution for revert
old_res="$current_res"

# Apply immediately (not persisted yet)
hyprctl keyword monitor "$EXT,$selected,$current_pos,$current_scale"

# Confirmation countdown — terminal stays open
TIMEOUT=10
confirmed=false
for ((i=TIMEOUT; i>0; i--)); do
  printf "\rKeep %s? ENTER=confirm, reverting in %2d..." "$selected" "$i"
  if read -t 1 -r; then
    confirmed=true
    break
  fi
done
echo ""

if [[ "$confirmed" == true ]]; then
  # Persist to monitors.conf
  new_line="monitor=${EXT},${selected},${current_pos},${current_scale}"
  if grep -q "^monitor=${EXT}," "$MONITORS_CONF"; then
    sed -i "s|^monitor=${EXT},.*|${new_line}|" "$MONITORS_CONF"
  else
    echo "$new_line" >> "$MONITORS_CONF"
  fi
  echo "Saved."
else
  # Revert to old resolution
  hyprctl keyword monitor "$EXT,$old_res,$current_pos,$current_scale"
  echo "Reverted to $old_res"
fi
