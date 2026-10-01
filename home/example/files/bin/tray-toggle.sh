#!/usr/bin/env bash
# Show/hide the drop-down system tray (eww). Starts the tray if it is not
# running yet. Usage: tray-toggle.sh [start]
set -u

if ! eww ping >/dev/null 2>&1; then
   eww daemon
   for _ in {1..50}; do
      eww ping >/dev/null 2>&1 && break
      sleep 0.1
   done
fi
eww active-windows 2>/dev/null | grep -q '^tray' || eww open tray

[[ "${1:-}" == start ]] && exit 0

if [[ "$(eww get tray_open)" == true ]]; then
   eww update tray_open=false
else
   eww update tray_open=true
fi
