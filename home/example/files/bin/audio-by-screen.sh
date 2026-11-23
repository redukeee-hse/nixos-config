#!/usr/bin/env bash
# Sound follows the screen: an app whose window is on the external monitor
# plays through the monitor's speakers (its DisplayPort audio), one on the
# laptop through the laptop. Re-checked whenever a stream starts or a window,
# workspace or monitor moves.
#
# A stream belongs to the window whose process is it or one of its parents
# (browsers play from a child process). If an app has windows on both
# screens, the most recently focused one decides.
# Only when the default output is the laptop's own sound card: with
# Bluetooth or USB headphones as default, everything stays there.
set -u

sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
card=alsa_output.pci-   # the laptop's sound card: speakers and DP outputs

# Parent pid, from /proc/PID/stat (the name field may hold spaces).
ppid_of() {
  local stat
  stat=$(cat "/proc/$1/stat" 2>/dev/null) || return 1
  stat=${stat##*) }
  set -- $stat
  echo "$2"
}

sync() {
  local default sinks laptop monitor clients
  default=$(pactl get-default-sink)
  sinks=$(pactl -f json list sinks 2>/dev/null)
  if [[ $default != "$card"* ]]; then
    # Headphones took over: bring back streams we sent to the laptop's card.
    local index sink _pid
    while read -r index sink _pid; do
      [[ $sink == "$card"* ]] && pactl move-sink-input "$index" "$default"
    done < <(streams "$sinks")
    return 0
  fi
  # The monitor: the DP output whose port reports a connected display.
  monitor=$(jq -r '[.[] | select(.name | test("HDMI"))
    | select(any(.ports[]; .availability == "available"))][0].name // empty' <<<"$sinks")
  [[ -n $monitor ]] || return 0
  if [[ $default == *HDMI* ]]; then
    laptop=$(jq -r '[.[] | select(.name | test("HDMI") | not)
      | select(.name | startswith("'"$card"'"))][0].name // empty' <<<"$sinks")
  else
    laptop=$default
  fi
  [[ -n $laptop ]] || return 0

  # pid -> "eDP-1" or another monitor name, most recently focused window first.
  clients=$(hyprctl -j clients | jq -r --argjson mons "$(hyprctl -j monitors)" '
    sort_by(.focusHistoryID)[]
    | .monitor as $m | "\(.pid) \(($mons[] | select(.id == $m) | .name) // "")"')
  declare -A screen=()
  local pid mon
  while read -r pid mon; do
    [[ -n $mon && -z ${screen[$pid]:-} ]] && screen[$pid]=$mon
  done <<<"$clients"

  local index sink spid p target
  while read -r index sink spid; do
    [[ $spid =~ ^[0-9]+$ ]] || continue
    target=
    p=$spid
    for _ in {1..12}; do
      if [[ -n ${screen[$p]:-} ]]; then
        [[ ${screen[$p]} == eDP-* ]] && target=$laptop || target=$monitor
        break
      fi
      p=$(ppid_of "$p") || break
      (( p > 1 )) || break
    done
    [[ -n $target && $sink != "$target" ]] && pactl move-sink-input "$index" "$target"
  done < <(streams "$sinks")
}

# "INDEX SINK-NAME PID" per playing stream. The text listing, not -f json:
# pactl's JSON writer chokes on non-ASCII titles (Cyrillic, "·") and drops
# the stream's properties.
streams() {
  local -A names=()
  local i n
  while read -r i n; do names[$i]=$n; done < <(jq -r '.[] | "\(.index) \(.name)"' <<<"$1")
  pactl list sink-inputs | awk '
    function out() { if (idx != "") print idx, sink, pid }
    /^Sink Input #/ { out(); idx = substr($3, 2); sink = ""; pid = "" }
    /^\tSink: / { sink = $2 }
    /application\.process\.id = / { gsub(/"/, "", $3); pid = $3 }
    END { out() }' |
  while read -r i n pid; do echo "$i ${names[$n]:-} ${pid:-}"; done
}

events() {
  socat -U - "UNIX-CONNECT:$sock" | grep --line-buffered -E \
    '^(openwindow|movewindow|moveworkspace|monitoradded|monitorremoved|activewindowv2)>>' &
  pactl subscribe | grep --line-buffered -E "'new' on sink-input|on server" &
  wait
}

sync
events | while read -r _; do
  # Gather a burst of events into one pass.
  while read -r -t 0.3 _; do :; done
  sync
done
