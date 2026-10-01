#!/usr/bin/env bash
# Show a static wallpaper (or a solid color with --color RRGGBB) through awww.
set -uo pipefail

pkill -x mpvpaper 2>/dev/null

if ! awww query >/dev/null 2>&1; then
   awww-daemon >/dev/null 2>&1 &
   for _ in $(seq 50); do
      awww query >/dev/null 2>&1 && break
      sleep 0.1
   done
fi

if [[ "${1:-}" == "--color" ]]; then
   awww clear "${2:-000000}"
else
   awww img "$1" --resize crop \
      --transition-type grow --transition-pos bottom \
      --transition-duration 1.2 --transition-fps 60
fi
