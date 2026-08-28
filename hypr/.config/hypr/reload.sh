#!/bin/bash
source "$HOME/.local/bin/err-notify"

# Re-parse hyprland.lua/conf (window rules, look&feel, ...). Without this a
# reload would only bounce the helper daemons and silently ignore config edits.
hyprctl reload

# Restart via systemd so the handler always has exactly one owner. A setsid
# respawn here used to orphan the handler outside systemd; the next Hyprland
# start then launched a second instance beside the stale orphan, and both
# fought over the bars (the exact scenario hyprland.lua warns about).
systemctl --user restart monitor-handler.service
