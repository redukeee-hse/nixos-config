#!/usr/bin/env bash
# Light/dark mode. The mode is stored in ~/.config/current/theme-mode and picks
# the wallpaper folder (~/Wallpapers/Pictures/Light or Dark), the pywal palette
# variant, the GTK theme and the Waybar colors.
# Usage: theme-mode.sh [toggle|light|dark|get]
set -uo pipefail

current="$HOME/.config/current"
mode_file="$current/theme-mode"
pictures="$HOME/Wallpapers/Pictures"

mode=$(cat "$mode_file" 2>/dev/null)
[[ "$mode" == light ]] || mode=dark

case "${1:-toggle}" in
   get)
      echo "$mode"
      exit 0
      ;;
   toggle) [[ "$mode" == dark ]] && mode=light || mode=dark ;;
   light | dark) mode=$1 ;;
   *)
      echo "usage: theme-mode.sh [toggle|light|dark|get]" >&2
      exit 2
      ;;
esac

folder="$pictures/${mode^}"
mkdir -p "$current" "$pictures/Light" "$pictures/Dark"
printf '%s\n' "$mode" > "$mode_file"
# The wallpaper picker (Ctrl+Super+Space) lists this folder.
ln -nsf "$folder" "$current/wallpaper-dir"

if [[ "$mode" == light ]]; then
   scheme=prefer-light gtk_theme=Adwaita icons=Papirus
else
   scheme=prefer-dark gtk_theme=Adwaita-dark icons=Papirus-Dark
fi
# libadwaita and the settings portal (browsers, Electron, Qt) follow color-scheme;
# GTK3 apps only switch through the theme name.
dconf write /org/gnome/desktop/interface/color-scheme "'$scheme'"
dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'"
dconf write /org/gnome/desktop/interface/icon-theme "'$icons'"
# Waybar imports this file; wal-color-export.sh reloads it below.
ln -nsf "$HOME/.config/waybar/colors-$mode.css" "$current/waybar-colors.css"
if [[ "$mode" == light ]]; then
   notify-send -h string:x-canonical-private-synchronous:theme-mode -t 2000 "󰖨  Light theme"
else
   notify-send -h string:x-canonical-private-synchronous:theme-mode -t 2000 "󰽥  Dark theme"
fi

# Back to the last wallpaper of this mode, otherwise a random one from its folder.
img=$(readlink -e "$current/wallpaper-$mode" 2>/dev/null)
if [[ -z "$img" ]]; then
   mapfile -t images < <(find "$folder/" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))
   ((${#images[@]})) && img=${images[RANDOM % ${#images[@]}]}
fi

if [[ -n "$img" ]]; then
   "$HOME/.config/quickshell/hyprquickpaper/commands.sh" "$img"
else
   notify-send -t 3000 "No wallpapers in $folder" "Keeping the current one"
   "$HOME/.local/share/custom/bin/apply-palette.sh" "$current/Wallpapers/Picture.png" 0.7
fi
