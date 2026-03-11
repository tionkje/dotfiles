#!/bin/bash

handle() {
  # echo $1;
  case $1 in
    monitoraddedv2*);;
    monitoradded*)
      monitor=${1#monitoradded>>}
      if [[ "$monitor" != "eDP-1" ]]; then
        if [[ -f /tmp/hypr-presentation-mode ]]; then
          # Presentation mode: only put presentation WS on external
          hyprctl dispatch moveworkspacetomonitor name:presentation "$monitor"
        else
          hyprctl dispatch moveworkspacetomonitor 1 "$monitor"
          hyprctl dispatch moveworkspacetomonitor 2 "$monitor"
          hyprctl dispatch moveworkspacetomonitor 3 "$monitor"
          hyprctl dispatch moveworkspacetomonitor 4 "$monitor"
          hyprctl dispatch moveworkspacetomonitor 5 "$monitor"
        fi
        hyprctl dispatch moveworkspacetomonitor 6 "eDP-1"
        hyprctl dispatch moveworkspacetomonitor 7 "eDP-1"
        ~/.config/hypr/eww-sidebar.sh
      fi
      ;;
    monitorremoved*)
      ~/.config/hypr/eww-sidebar.sh
      ;;
  esac
}

sleep 5
for monitorname in $(hyprctl -j monitors | jq -r '.[].name'); do
  handle "monitoradded>>$monitorname"
done
~/.config/hypr/eww-sidebar.sh
waybar &

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  handle "$line"
done &

# Re-evaluate sidebar on wake from sleep
dbus-monitor --system "type=signal,interface=org.freedesktop.login1.Manager,member=PrepareForSleep" |
  while read -r line; do
    if echo "$line" | grep -q "boolean false"; then
      sleep 2
      ~/.config/hypr/eww-sidebar.sh
    fi
  done &

wait

