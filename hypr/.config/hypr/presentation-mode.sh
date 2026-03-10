#!/bin/bash
STATE_FILE="/tmp/hypr-presentation-mode"
LAPTOP="eDP-1"

# Find first external monitor (not eDP-1)
EXT=$(hyprctl -j monitors | jq -r '.[] | select(.name != "'"$LAPTOP"'") | .name' | head -1)

if [[ -z "$EXT" ]]; then
  notify-send "Presentation Mode" "No external monitor detected"
  exit 1
fi

if [[ -f "$STATE_FILE" ]]; then
  # === Toggle OFF ===
  # Move WS 1-5 back to external
  for ws in 1 2 3 4 5; do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$EXT"
  done
  # Focus WS 1 on external
  hyprctl dispatch focusmonitor "$EXT"
  hyprctl dispatch workspace 1
  rm "$STATE_FILE"
  notify-send "Presentation Mode" "OFF — normal layout restored"
else
  # === Toggle ON ===
  # Move WS 1-5 to laptop
  for ws in 1 2 3 4 5; do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$LAPTOP"
  done
  # Create empty presentation workspace on external
  hyprctl dispatch focusmonitor "$EXT"
  hyprctl dispatch workspace name:presentation
  # Focus back on laptop
  hyprctl dispatch focusmonitor "$LAPTOP"
  touch "$STATE_FILE"
  notify-send "Presentation Mode" "ON — external shows empty workspace"
fi
