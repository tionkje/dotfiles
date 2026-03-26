#!/bin/bash
# Opens eww sidebar on the correct monitor:
# - External monitor in normal mode
# - Laptop (eDP-1) in presentation mode or when no external is connected
LAPTOP="eDP-1"
MONITORS_JSON=$(hyprctl -j monitors)

EXT=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name != "'"$LAPTOP"'") | .name' | head -1)

if [[ -n "$EXT" && ! -f /tmp/hypr-presentation-mode ]]; then
  TARGET="$EXT"
else
  TARGET="$LAPTOP"
fi

# eww uses GDK monitor names (model) not Wayland connector names
SCREEN=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name == "'"$TARGET"'") | .model')

eww kill 2>/dev/null
pkill -f 'eww daemon'
while eww ping 2>/dev/null; do sleep 0.1; done
setsid eww daemon &
sleep 1

eww open sidebar --screen "$SCREEN"
