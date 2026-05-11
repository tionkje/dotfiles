#!/bin/bash

# Tear down monitor-handler and everything it spawned (waybar, eww daemon,
# socat/inotify/dbus watchers) in one shot via its process group, set up by
# the setsid below. No hand-maintained pkill list needed.

if pid=$(pgrep -of monitor-handler.sh); then
  pgid=$(ps -o pgid= -p "$pid" | tr -d ' ')
  kill -TERM -"$pgid"
  while pgrep -f monitor-handler.sh >/dev/null; do sleep 0.05; done
fi

MONITOR_HANDLER_INIT_DELAY=0 setsid ~/.config/hypr/monitor-handler.sh &
