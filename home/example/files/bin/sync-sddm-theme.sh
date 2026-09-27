#!/usr/bin/env bash
set -euo pipefail

state_dir="/var/lib/nixos-sddm"
wallpaper="${1:-$HOME/.config/current/Wallpapers/Picture.png}"
palette="$HOME/.cache/wal/colors.json"

[[ -d "$state_dir" && -w "$state_dir" ]] || exit 0
[[ -r "$wallpaper" && -r "$palette" ]] || exit 0

background_tmp=$(mktemp "$state_dir/.background.XXXXXX")
theme_tmp=$(mktemp "$state_dir/.theme.XXXXXX")
trap 'rm -f "$background_tmp" "$theme_tmp"' EXIT

cp -- "$wallpaper" "$background_tmp"
chmod 0644 "$background_tmp"

foreground=$(jq -r '.special.foreground' "$palette")
background=$(jq -r '.special.background' "$palette")
accent=$(jq -r '.colors.color4' "$palette")
muted=$(jq -r '.colors.color8' "$palette")

{
  printf '%s\n' '[General]'
  printf 'TextColor=%s\n' "$foreground"
  printf 'AccentColor=%s\n' "$accent"
  printf 'MutedColor=%s\n' "$muted"
  printf 'OverlayColor=#52%s\n' "${background#\#}"
  printf 'FieldColor=#8a%s\n' "${background#\#}"
} > "$theme_tmp"
chmod 0644 "$theme_tmp"

mv -f "$background_tmp" "$state_dir/background.jpg"
mv -f "$theme_tmp" "$state_dir/theme.conf"
trap - EXIT
