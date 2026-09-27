#!/usr/bin/env bash
set -euo pipefail

sink="@DEFAULT_AUDIO_SINK@"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"

# Keep simultaneous hardware events from racing each other.
exec 9>"$runtime_dir/nixos-volume.lock"
flock 9

# Some laptop firmware emits the same multimedia key event several times.
# Ignore copies arriving within 150 ms while keeping normal key presses responsive.
debounce_file="$runtime_dir/nixos-volume-last-event-${1:-unknown}"
now_ns=$(date +%s%N)
last_ns=0
[[ -r "$debounce_file" ]] && read -r last_ns < "$debounce_file" || true
if [[ "$last_ns" =~ ^[0-9]+$ ]] && ((now_ns - last_ns < 150000000)); then
  exit 0
fi
printf '%s\n' "$now_ns" > "$debounce_file"

volume_state=$(wpctl get-volume "$sink")
current=$(awk '{ printf "%d", ($2 * 100) + 0.5 }' <<<"$volume_state")
muted=false
[[ "$volume_state" == *MUTED* ]] && muted=true

case "${1:-}" in
  up)
    target=$((current + 5))
    ((target > 100)) && target=100
    wpctl set-volume --limit 1.0 "$sink" "${target}%"
    wpctl set-mute "$sink" 0
    muted=false
    ;;
  down)
    target=$((current - 5))
    ((target < 0)) && target=0
    wpctl set-volume "$sink" "${target}%"
    ;;
  mute)
    wpctl set-mute "$sink" toggle
    volume_state=$(wpctl get-volume "$sink")
    [[ "$volume_state" == *MUTED* ]] && muted=true || muted=false
    target=$(awk '{ printf "%d", ($2 * 100) + 0.5 }' <<<"$volume_state")
    ;;
  *)
    printf 'Usage: %s {up|down|mute}\n' "$0" >&2
    exit 2
    ;;
esac

if $muted; then
  notify-send -h string:x-canonical-private-synchronous:volume \
    -h int:value:0 -t 1200 "🔇"
else
  notify-send -h string:x-canonical-private-synchronous:volume \
    -h int:value:"$target" -t 1200 "Volume ${target}%"
fi
