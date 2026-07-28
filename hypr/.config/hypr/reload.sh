#!/bin/bash
source "$HOME/.local/bin/err-notify"

# Re-parse hyprland.lua/conf (window rules, look&feel, ...). Without this a
# reload would only bounce the helper daemons and silently ignore config edits.
hyprctl reload

# Tear down a helper and everything it spawned in one shot via its process
# group (set up by the setsid launches below / at hyprland startup). No
# hand-maintained pkill list needed.
kill_pg() {
  local pid pgid
  # Kill every matching process group, not just the oldest: repeated reloads
  # leave multiple setsid groups behind, and waiting on pgrep with survivors
  # from other groups hangs this loop forever.
  local pids
  # pgrep exit 1 = nothing running, which is a normal state here
  pids=$(pgrep -f "$1") || pids=""
  for pid in $pids; do
    if pgid=$(ps -o pgid= -p "$pid" | tr -d ' ') && [[ -n $pgid ]]; then
      if ! kill -TERM -"$pgid"; then
        echo "reload.sh: process group $pgid already gone" >&2
      fi
    fi
  done
  while pgrep -f "$1" >/dev/null; do sleep 0.05; done
}

kill_pg monitor-handler.sh

MONITOR_HANDLER_INIT_DELAY=0 setsid ~/.config/hypr/monitor-handler.sh &
