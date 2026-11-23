#!/usr/bin/env bash
# Looks after a monitor plugged in during the session.
#
# 1. Lights it if Hyprland connected it but could not turn it on.
#    Aquamarine sometimes hands a new monitor a CRTC that the kernel still
#    keeps on a dead connector (seen with the USB-C to DisplayPort cable: the
#    Samsung showed up on DP-1 while CRTC 271 stayed on the empty DP-3).
#    Every modeset then fails with EINVAL, the monitor sits at 0x0 and shows
#    "no signal". A trip to another VT and back makes Hyprland reset all
#    outputs, which clears it. chvt needs root; modules/desktop/hyprland.nix
#    allows it without a password.
# 2. Puts the wallpaper on it. awww and mpvpaper only cover the outputs that
#    exist when they start, so a later monitor stays black.
set -u

sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
chvt=/run/current-system/sw/bin/chvt
last_heal=0

broken() {
  hyprctl -j monitors all | jq -e 'any(.[]; .disabled == false and .width == 0)' >/dev/null
}

heal() {
  sleep 2
  broken || return 0
  local session vt spare
  session=$(loginctl show-user "$USER" -p Display --value)
  vt=$(loginctl show-session "$session" -p VTNr --value)
  [[ -n $vt && $vt != 0 ]] || return 0
  spare=$(( vt == 2 ? 3 : 2 ))
  sudo -n "$chvt" "$spare" && sleep 1 && sudo -n "$chvt" "$vt"
}

wallpaper() {
  local output=$1 pid img
  # Give the output a moment to get a mode and reach the wallpaper daemons.
  sleep 2
  pid=$(pgrep -xo mpvpaper)
  if [[ -n $pid ]]; then
    # Live wallpaper: one more mpvpaper with the same options and video,
    # for this output only (argv: mpvpaper -o OPTS OUTPUT FILE).
    local -a argv
    mapfile -d '' argv < "/proc/$pid/cmdline"
    [[ ${#argv[@]} -ge 5 ]] || return 0
    pgrep -xa mpvpaper | grep -qF " $output " && return 0
    mpvpaper -o "${argv[2]}" "$output" "${argv[4]}" >/dev/null 2>&1 &
    disown
    return 0
  fi
  # Static wallpaper: the image another screen already shows.
  img=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)
  [[ -n $img ]] && awww img -o "$output" "$img" --resize crop --transition-type none
}

socat -U - "UNIX-CONNECT:$sock" | while read -r line; do
  case $line in
    monitoradded\>\>*)
      wallpaper "${line#*>>}" &
      # The VT trip re-adds monitors itself; one try per 30 s, no loops.
      now=$(date +%s)
      if (( now - last_heal >= 30 )); then
        last_heal=$now
        heal &
      fi
      ;;
  esac
done
