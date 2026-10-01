#!/usr/bin/env bash
WALJSON="$HOME/.cache/wal/colors.json"
TPL="$HOME/.config/current/wal-colors-template.css"
OUT="$HOME/.config/current/wal-colors.css"

# Fresh system: build the palette from the current wallpaper once.
if [[ ! -r "$WALJSON" ]]; then
   wallpaper="$HOME/.config/current/Wallpapers/Picture.png"
   [[ -r "$wallpaper" ]] || exit 0
   wal -i "$wallpaper" -n -s -q --saturate 0.7 -b 010101 || exit 0
fi

# grab colors from pywal
BG=$(jq -r '.special.background' "$WALJSON")
FG=$(jq -r '.special.foreground' "$WALJSON")
ACCENT=$(jq -r '.colors.color4' "$WALJSON") # tweak which color slot you like
BORDER="$ACCENT"

# create semi-transparent rgba versions (optional)
BG_ALPHA="rgba(${BG#\#}, 0.1)" # not valid hex→rgba, so we’ll patch below

# this converts hex to rgba manually
hex_to_rgba() {
   local hex=${1#\#}
   local r=$((16#${hex:0:2}))
   local g=$((16#${hex:2:2}))
   local b=$((16#${hex:4:2}))
   local a=${2:-1}
   echo "rgba(${r}, ${g}, ${b}, ${a})"
}

# do replacements
cp "$TPL" "$OUT"

sed -i "s|<selected>|$ACCENT|g" "$OUT"
sed -i "s|<text>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<base>|$(hex_to_rgba "$BG" 0.4)|g" "$OUT"
sed -i "s|<border>|$(hex_to_rgba "$ACCENT" 0.7)|g" "$OUT"
sed -i "s|<foreground>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<background>|$(hex_to_rgba "$BG" 0.9)|g" "$OUT"

# Shared translucent palette for the Wi-Fi picker. This is regenerated every
# time the wallpaper changes (apply-palette.sh).
ROFI_WIFI_COLORS="$HOME/.config/rofi/wifi-colors.rasi"
COLOR4=$(jq -r '.colors.color4' "$WALJSON")
COLOR8=$(jq -r '.colors.color8' "$WALJSON")
COLOR12=$(jq -r '.colors.color12' "$WALJSON")
COLOR15=$(jq -r '.colors.color15' "$WALJSON")

# Rofi reads its theme only when the window opens. Remember an open Wi-Fi
# picker so it can be reopened immediately with the freshly generated palette.
mapfile -t WIFI_MENU_PIDS < <(pgrep -u "$UID" -f 'rofi .*wifi[.]rasi' || true)
ROFI_WIFI_COLORS_TMP="${ROFI_WIFI_COLORS}.tmp.$$"

{
   printf '%s\n' '* {'
   printf '    wifi-bg: %s;\n' "$(hex_to_rgba "$BG" 0.72)"
   printf '    wifi-surface: %s;\n' "$(hex_to_rgba "$COLOR8" 0.18)"
   printf '    wifi-surface-hover: %s;\n' "$(hex_to_rgba "$COLOR12" 0.28)"
   printf '    wifi-accent: %s;\n' "$COLOR12"
   printf '    wifi-accent-soft: %s;\n' "$(hex_to_rgba "$COLOR4" 0.42)"
   printf '    wifi-border: %s;\n' "$(hex_to_rgba "$COLOR12" 0.72)"
   printf '    wifi-text: %s;\n' "$FG"
   printf '    wifi-muted: %s;\n' "$COLOR15"
   printf '%s\n' '}'
} > "$ROFI_WIFI_COLORS_TMP"
mv -f "$ROFI_WIFI_COLORS_TMP" "$ROFI_WIFI_COLORS"

if ((${#WIFI_MENU_PIDS[@]})); then
   for wifi_menu_pid in "${WIFI_MENU_PIDS[@]}"; do
      kill "$wifi_menu_pid" 2>/dev/null || true
   done
   (
      sleep 0.15
      exec networkmanager_dmenu
   ) >/dev/null 2>&1 &
fi

# SwayNC does not inherit the GTK/Waybar palette.
mkdir -p "$HOME/.config/current"
swaync_tmp=$(mktemp "$HOME/.config/current/.swaync-colors.XXXXXX")
{
   printf '@define-color nc-bg %s;\n' "$(hex_to_rgba "$BG" 0.19)"
   printf '@define-color nc-panel %s;\n' "$(hex_to_rgba "$BG" 0.55)"
   printf '@define-color nc-fg %s;\n' "$FG"
   printf '@define-color nc-accent %s;\n' "$ACCENT"
   printf '@define-color nc-border %s;\n' "$(hex_to_rgba "$ACCENT" 0.5)"
} > "$swaync_tmp"
mv -f "$swaync_tmp" "$HOME/.config/current/swaync-colors.css"
if pgrep -x swaync >/dev/null; then
   timeout 2 swaync-client --reload-css >/dev/null 2>&1 || true
fi

# Recolor terminals that are already open. wal runs with -s so it never
# broadcasts on its own; VS Code terminals keep their own theme.
for pts in /dev/pts/[0-9]*; do
   [[ -O "$pts" && -w "$pts" ]] || continue
   in_vscode=0
   for pid in $(ps -t "${pts#/dev/}" -o pid= 2>/dev/null); do
      if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -qx 'TERM_PROGRAM=vscode'; then
         in_vscode=1
         break
      fi
   done
   ((in_vscode)) || timeout 1 cp "$HOME/.cache/wal/sequences" "$pts" 2>/dev/null &
done

pkill walker
pkill -SIGUSR2 -x waybar 2>/dev/null || true
"$HOME/.local/share/custom/bin/sync-sddm-theme.sh" || true

# Persist the border palette across Hyprland reloads and apply it immediately.
hypr_colors="$HOME/.config/current/hypr-colors.conf"
hypr_tmp=$(mktemp "${hypr_colors}.XXXXXX")
printf 'general:col.active_border = rgba(%see) rgba(%s88) 45deg\n' "${ACCENT#\#}" "${COLOR12#\#}" > "$hypr_tmp"
mv -f "$hypr_tmp" "$hypr_colors"
hyprctl keyword general:col.active_border "rgba(${ACCENT#\#}ee) rgba(${COLOR12#\#}88) 45deg" >/dev/null 2>&1 || true
