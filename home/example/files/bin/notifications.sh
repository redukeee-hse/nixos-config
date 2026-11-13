#!/usr/bin/env bash
# Notifications switch between the shell (Quickshell, Notifications.qml, the
# default) and SwayNC (rosa.css), so either can be used and rolled back.
#   notifications.sh toggle        open/close the notification centre
#   notifications.sh dnd           toggle Do Not Disturb
#   notifications.sh status        stream Waybar JSON (custom/notification)
#   notifications.sh use shell|swaync
set -uo pipefail

mode_file="$HOME/.config/current/notification-daemon"
status_file="$HOME/.cache/notifications-status.json"
mode=$(cat "$mode_file" 2>/dev/null || echo shell)
[[ "$mode" == swaync ]] || mode=shell

case "${1:-toggle}" in
   toggle)
      [[ $mode == swaync ]] && exec swaync-client -t -sw
      exec qs ipc call notifications toggle
      ;;
   dnd)
      [[ $mode == swaync ]] && exec swaync-client -d -sw
      exec qs ipc call notifications dnd
      ;;
   status)
      [[ $mode == swaync ]] && exec swaync-client -swb
      [[ -s "$status_file" ]] || echo '{"text": "", "alt": "none", "class": "none"}' > "$status_file"
      exec tail -n 1 -F "$status_file" 2>/dev/null
      ;;
   use)
      new=${2:-}
      [[ $new == shell || $new == swaync ]] || { echo "use: shell or swaync" >&2; exit 2; }
      mkdir -p "$(dirname "$mode_file")"
      echo "$new" > "$mode_file"
      if [[ $new == swaync ]]; then
         pkill -x quickshell; pkill -x qs
         systemctl --user reset-failed swaync.service 2>/dev/null
         systemctl --user start swaync.service
         hyprctl dispatch exec qs >/dev/null
      else
         systemctl --user stop swaync.service
         pkill -x quickshell; pkill -x qs
         hyprctl dispatch exec qs >/dev/null
      fi
      pkill -SIGUSR2 waybar
      notify-send -a System "Notifications" "Now drawn by $new"
      ;;
   *)
      echo "usage: notifications.sh [toggle|dnd|status|use shell|swaync]" >&2
      exit 2
      ;;
esac
