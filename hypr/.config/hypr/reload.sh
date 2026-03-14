#!/bin/bash

# Kill existing monitor-handler and its spawned child processes
pkill -f 'monitor-handler\.sh'
pkill -f 'inotifywait.*\.config/eww'
pkill -f 'socat.*socket2\.sock'
pkill -f 'dbus-monitor.*PrepareForSleep'
killall waybar

# Reload eww config
eww reload

# Restart monitor-handler with no init delay (it starts eww-sidebar + waybar)
MONITOR_HANDLER_INIT_DELAY=0 setsid ~/.config/hypr/monitor-handler.sh &
