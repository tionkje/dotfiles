#!/bin/bash

assign_workspaces() {
  local monitor=$1
  if [[ "$monitor" != "eDP-1" ]]; then
    if [[ -f /tmp/hypr-presentation-mode ]]; then
      hyprctl dispatch moveworkspacetomonitor name:presentation "$monitor"
    else
      hyprctl dispatch moveworkspacetomonitor name:work "$monitor"
      hyprctl dispatch moveworkspacetomonitor name:edit "$monitor"
      hyprctl dispatch moveworkspacetomonitor name:read "$monitor"
      hyprctl dispatch moveworkspacetomonitor name:talk "$monitor"
      hyprctl dispatch moveworkspacetomonitor name:youtube "$monitor"
    fi
    hyprctl dispatch moveworkspacetomonitor name:spotify "eDP-1"
    hyprctl dispatch moveworkspacetomonitor name:meet "eDP-1"
  fi
}

handle() {
  case $1 in
    monitoraddedv2*);;
    monitoradded*)
      assign_workspaces "${1#monitoradded>>}"
      ~/.config/hypr/eww-sidebar.sh
      ~/.config/waybar/reload.sh
      ;;
    monitorremoved*)
      ~/.config/hypr/eww-sidebar.sh
      ~/.config/waybar/reload.sh
      ;;
  esac
}

sleep "${MONITOR_HANDLER_INIT_DELAY:-5}"
for monitorname in $(hyprctl -j monitors | jq -r '.[].name'); do
  assign_workspaces "$monitorname"
done
~/.config/hypr/eww-sidebar.sh
waybar &

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  handle "$line"
done &

# Reload waybar after eww auto-reloads on config file change
inotifywait -m -e modify -r ~/.config/eww/ |
  while read -r; do
    sleep 1
    killall -SIGUSR2 waybar
  done &

# Re-evaluate sidebar on wake from sleep
dbus-monitor --system "type=signal,interface=org.freedesktop.login1.Manager,member=PrepareForSleep" |
  while read -r line; do
    if echo "$line" | grep -q "boolean false"; then
      sleep 2
      ~/.config/hypr/eww-sidebar.sh
      ~/.config/waybar/reload.sh
    fi
  done &

wait

