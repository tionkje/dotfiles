#!/bin/bash
source "$HOME/.local/bin/err-notify"
# Opens eww sidebar on the correct monitor:
# - External monitor in normal mode
# - Laptop (eDP-1) in presentation mode or when no external is connected
LAPTOP="eDP-1"

# Serialize all callers (monitor-handler, presentation-mode, manual): two
# interleaved kill/daemon/open dances end with a self-daemonized `eww open`
# holding one sidebar plus a real daemon holding another.
exec 9>"$XDG_RUNTIME_DIR/eww-sidebar.lock"
flock -w 60 9 || exit 1

MONITORS_JSON=$(hyprctl -j monitors)

EXT=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name != "'"$LAPTOP"'") | .name' | head -1)

if [[ -n "$EXT" && ! -f /tmp/hypr-presentation-mode ]]; then
  TARGET="$EXT"
else
  TARGET="$LAPTOP"
fi

# eww uses GDK monitor names (model) not Wayland connector names
SCREEN=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name == "'"$TARGET"'") | .model')

# Daemon not running is a normal state here, not an error worth notifying
if ! eww kill 2>/dev/null; then
  echo "eww-sidebar: no eww daemon answering, continuing" >&2
fi
# match '^eww ' not 'eww daemon': an `eww open` that raced the daemon
# daemonizes itself with its original cmdline
if ! pkill -f '^eww '; then
  echo "eww-sidebar: no eww daemon process to kill, continuing" >&2
fi
while eww ping 2>/dev/null; do sleep 0.1; done
# 9>&- : don't leak the lock fd into the daemon (would hold the lock forever)
setsid eww daemon 9>&- &
until eww ping 2>/dev/null; do sleep 0.1; done

eww open sidebar --screen "$SCREEN" 9>&-
