#!/usr/bin/env bash
set -u
export GDK_BACKEND=wayland

log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
mkdir -p "$log_dir"

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"$runtime_dir/nixos-waybar-auto-${HYPRLAND_INSTANCE_SIGNATURE:?}.lock"
flock -n 9 || exit 0

bar_visible=true
bar_pid=""
bar_mode=min

start_bar() {
   local mode="$1"
   bar_mode="$mode"
   setsid waybar \
      -c "$HOME/.config/waybar/${mode}.jsonc" \
      -s "$HOME/.config/waybar/${mode}.css" \
      9>&- >>"$log_dir/waybar.log" 2>&1 &
   bar_pid=$!
}

stop_bar() {
   if [[ -n "$bar_pid" ]] && kill -0 "$bar_pid" 2>/dev/null; then
      kill -TERM -- "-$bar_pid" 2>/dev/null || kill -TERM "$bar_pid" 2>/dev/null || true
      wait "$bar_pid" 2>/dev/null || true
   fi
   bar_pid=""
}

shutdown() {
   trap - EXIT INT TERM
   stop_bar
   exit 0
}

trap stop_bar EXIT
trap shutdown INT TERM

# The compositor creates its control socket after it starts exec-once commands.
for attempt in {1..100}; do
   [[ -S "$runtime_dir/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock" ]] && break
   sleep 0.1
done

start_bar min

while [[ -S "$runtime_dir/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock" ]]; do
   if ! kill -0 "$bar_pid" 2>/dev/null; then
      wait "$bar_pid" 2>/dev/null || true
      sleep 2
      start_bar "$bar_mode"
   fi
   Y=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null)
   [[ -z "$Y" ]] && sleep 0.1 && continue

   if ((Y <= 5)) && $bar_visible; then
      sleep 0.4
      y=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null)
      [[ -z "$y" ]] && sleep 0.1 && continue

      if ((y <= 5)); then
         stop_bar
         start_bar max
         bar_visible=false
      fi
   elif ((Y > 40)) && ! $bar_visible; then
      stop_bar
      start_bar min
      bar_visible=true
   fi

   sleep 0.1
done
