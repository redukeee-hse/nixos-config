#!/usr/bin/env bash
# Clipboard history (Super+C). cliphist keeps text and images copied since
# login (watchers start in hyprland.conf); pick one in rofi to copy it again.
#   clipboard.sh         pick an entry
#   clipboard.sh wipe    forget the whole history
set -uo pipefail

case "${1:-pick}" in
   wipe)
      cliphist wipe
      notify-send -a Clipboard -i edit-paste "Clipboard history cleared"
      ;;
   pick)
      pkill -x rofi && exit 0
      entry=$(cliphist list | rofi -dmenu -i -p "" -display-columns 2 -mesg "Enter copy · Alt+Del forget" \
         -kb-custom-1 "Alt+Delete")
      status=$?
      [[ -n "$entry" ]] || exit 0
      if ((status == 10)); then
         printf '%s' "$entry" | cliphist delete
      else
         printf '%s' "$entry" | cliphist decode | wl-copy
      fi
      ;;
   *)
      echo "usage: clipboard.sh [pick|wipe]" >&2
      exit 2
      ;;
esac
