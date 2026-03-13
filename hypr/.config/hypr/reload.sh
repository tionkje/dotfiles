#!/bin/bash

# Kill existing monitor-handler and its spawned processes
pkill -f 'monitor-handler\.sh'
killall waybar

# Reload eww config
eww reload

# Restart monitor-handler with no init delay (it starts eww-sidebar + waybar)
MONITOR_HANDLER_INIT_DELAY=0 setsid ~/.config/hypr/monitor-handler.sh &
