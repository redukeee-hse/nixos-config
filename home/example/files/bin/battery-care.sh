#!/usr/bin/env bash
# Battery care, after Ryoku's ryoku-power and its battery alerts.
#   battery-care.sh watch          reapply the charge limit, then warn at 25%
#                                  and 10% while discharging (user service)
#   battery-care.sh limit [N|off]  show or set the charge limit (60–100)
set -uo pipefail

bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
limit_file="$HOME/.config/current/charge-limit"
warn=25
crit=10

apply_limit() {
   local n=$1
   [[ -n "$bat" && -w "$bat/charge_control_end_threshold" ]] || return 1
   # Start charging again 5% below the stop point so it doesn't cycle.
   [[ -w "$bat/charge_control_start_threshold" ]] && echo $((n - 5)) > "$bat/charge_control_start_threshold" 2>/dev/null
   echo "$n" > "$bat/charge_control_end_threshold"
}

case "${1:-watch}" in
   limit)
      if [[ -z "${2:-}" ]]; then
         cat "$bat/charge_control_end_threshold" 2>/dev/null || echo 100
         exit 0
      fi
      n=${2/off/100}
      [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 60 && n <= 100)) || { echo "limit: 60–100 or off" >&2; exit 2; }
      mkdir -p "$(dirname "$limit_file")"
      echo "$n" > "$limit_file"
      apply_limit "$n" || { echo "battery-care: no writable charge threshold" >&2; exit 1; }
      ;;
   watch)
      [[ -r "$limit_file" ]] && apply_limit "$(cat "$limit_file")"
      [[ -n "$bat" ]] || exit 0
      warned=""
      while sleep 60; do
         status=$(cat "$bat/status" 2>/dev/null)
         cap=$(cat "$bat/capacity" 2>/dev/null) || continue
         if [[ "$status" != Discharging ]]; then
            warned=""
            continue
         fi
         if ((cap <= crit)) && [[ "$warned" != crit ]]; then
            notify-send -a Battery -u critical -i battery-caution "Battery at ${cap}%" "Plug in the charger now."
            warned=crit
         elif ((cap <= warn)) && [[ -z "$warned" ]]; then
            notify-send -a Battery -i battery-low "Battery at ${cap}%" "Time to find a charger."
            warned=warn
         fi
      done
      ;;
   *)
      echo "usage: battery-care.sh [watch|limit [N|off]]" >&2
      exit 2
      ;;
esac
