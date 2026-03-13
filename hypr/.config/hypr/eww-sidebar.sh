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

MONITOR_HEIGHT=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name == "'"$TARGET"'") | .height')
LAYERS_JSON=$(hyprctl layers -j)
WAYBAR_HEIGHT=$(echo "$LAYERS_JSON" | jq '[.. | objects | select(.namespace == "waybar")] | max_by(.h) | .h // 0')
SIDEBAR_HEIGHT=$((MONITOR_HEIGHT - WAYBAR_HEIGHT))

eww kill 2>/dev/null
setsid eww daemon &
sleep 1
eww open sidebar --screen "$SCREEN" --arg height="${SIDEBAR_HEIGHT}px"
