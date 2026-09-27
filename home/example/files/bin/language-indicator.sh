#!/usr/bin/env bash
set -euo pipefail

keyboard="${1:-at-translated-set-2-keyboard}"
layout=$(hyprctl devices -j | jq -r --arg keyboard "$keyboard" '
  .keyboards[]
  | select(.name == $keyboard)
  | .active_keymap
' | head -n 1)

case "$layout" in
  Russian*) printf '%s\n' "ru" ;;
  English*) printf '%s\n' "eu" ;;
  *) printf '%s\n' "${layout:0:2}" | tr '[:upper:]' '[:lower:]' ;;
esac
