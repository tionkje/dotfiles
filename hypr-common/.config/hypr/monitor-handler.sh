#!/bin/bash
# Long-running event loop: err-notify surfaces failures without set -e, so a
# failed command notifies but never kills the handler.
source "$HOME/.local/bin/err-notify"

assign_workspaces() {
  local monitor=$1
  if [[ "$monitor" != "eDP-1" ]]; then
    if [[ -f /tmp/hypr-presentation-mode ]]; then
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:presentation]], monitor = [[$monitor]] })"
    else
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:work]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:edit]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:read]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:talk]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:youtube]], monitor = [[$monitor]] })"
      hypr-dispatch "hl.dsp.workspace.move({ workspace = [[name:incognito]], monitor = [[$monitor]] })"
    fi
    hypr-dispatch 'hl.dsp.workspace.move({ workspace = [[name:spotify]], monitor = [[eDP-1]] })'
    hypr-dispatch 'hl.dsp.workspace.move({ workspace = [[name:meet]], monitor = [[eDP-1]] })'
  fi
}

reload_bars() {
  # flock: two triggers can fire at once (monitor event + wake from sleep);
  # interleaved kill/start of waybar+eww leaves dead bars, so serialize
  (
    # -w 60: daemons used to inherit fd 9 and hold the lock forever, wedging
    # every later reload; timeout turns a repeat of that into a notification
    flock -w 60 9
    # 9>&- : don't leak the lock fd into waybar/eww daemons
    ~/.config/waybar/reload.sh 9>&-
    sleep 1
    ~/.config/hypr/eww-sidebar.sh 9>&-
  ) 9>"$XDG_RUNTIME_DIR/reload-bars.lock"
}

handle() {
  case $1 in
    monitoraddedv2*);;
    monitoradded*)
      assign_workspaces "${1#monitoradded>>}"
      reload_bars
      ~/.config/hypr/swaync-follow-main.sh
      ;;
    monitorremoved*)
      reload_bars
      ~/.config/hypr/swaync-follow-main.sh
      ;;
  esac
}

sleep "${MONITOR_HANDLER_INIT_DELAY:-5}"
for monitorname in $(hyprctl -j monitors | jq -r '.[].name'); do
  assign_workspaces "$monitorname"
done
reload_bars
~/.config/hypr/swaync-follow-main.sh

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  handle "$line"
done &

# Reload waybar after eww auto-reloads on config file change
inotifywait -m -e modify -r ~/.config/eww/ |
  while read -r; do
    sleep 1
    if ! killall -SIGUSR2 waybar; then
      echo "monitor-handler: waybar not running, skipping reload signal" >&2
    fi
  done &

# Re-evaluate sidebar on wake from sleep
dbus-monitor --system "type=signal,interface=org.freedesktop.login1.Manager,member=PrepareForSleep" |
  while read -r line; do
    if echo "$line" | grep -q "boolean false"; then
      sleep 2
      reload_bars
    fi
  done &

wait

