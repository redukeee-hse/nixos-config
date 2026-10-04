#!/usr/bin/env bash
# Switch between the balanced and power-saver profiles (power-profiles-daemon).
#   power-profile.sh toggle  flip the profile and refresh the Waybar indicator
#   power-profile.sh status  JSON for the Waybar module: empty unless power-saver is on
set -uo pipefail

case "${1:-status}" in
toggle)
   if [[ "$(powerprofilesctl get)" == power-saver ]]; then
      powerprofilesctl set balanced
   else
      powerprofilesctl set power-saver
   fi
   pkill -RTMIN+8 -x waybar 2>/dev/null || true
   ;;
status)
   if [[ "$(powerprofilesctl get 2>/dev/null)" == power-saver ]]; then
      echo '{"text": "󰌪", "class": "power-saver", "tooltip": "Включён режим энергосбережения\nНажмите, чтобы вернуть обычный режим"}'
   else
      echo '{"text": ""}'
   fi
   ;;
esac
