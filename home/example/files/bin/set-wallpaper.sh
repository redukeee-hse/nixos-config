#!/usr/bin/env bash
# Show a static wallpaper (or a solid color with --color RRGGBB) through awww.
# --instant skips awww's transition (used at login, where the session intro
# reveals the wallpaper).
set -uo pipefail

# Transition style, from ~/.config/current/wallpaper-transitions:
#   ryoku    (default) Ryoku's reveal: a random kind among grow, outer, wave,
#            wipe and center, starting at the mouse pointer, 2.2 s on its
#            InOutCubic curve.
#   classic  the previous one: a circle growing from the bottom in 1.2 s.
style=$(cat "$HOME/.config/current/wallpaper-transitions" 2>/dev/null || echo ryoku)
if [[ "$style" == classic ]]; then
   transition=(--transition-type grow --transition-pos bottom --transition-duration 1.2 --transition-fps 60)
else
   kinds=(grow outer wave wipe center grow outer)
   kind=${kinds[RANDOM % ${#kinds[@]}]}
   pos=$(hyprctl -j cursorpos 2>/dev/null | jq -r '"\(.x),\(.y)"' 2>/dev/null)
   # awww counts y from the bottom; Hyprland from the top.
   height=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused) | (.height / .scale | floor)' 2>/dev/null)
   if [[ "$pos" =~ ^[0-9.-]+,[0-9.-]+$ && "$height" =~ ^[0-9]+$ ]]; then
      pos="${pos%,*},$((height - ${pos#*,}))"
   else
      pos=center
   fi
   transition=(--transition-type "$kind" --transition-pos "$pos" --transition-angle $((RANDOM % 360))
      --transition-wave 28,14 --transition-duration 2.2 --transition-fps 60
      --transition-bezier .65,.05,.36,1)
fi
if [[ "${1:-}" == "--instant" ]]; then
   transition=(--transition-type none)
   shift
fi

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
   awww img "$1" --resize crop "${transition[@]}"
fi
