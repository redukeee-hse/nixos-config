#!/usr/bin/env bash
# Generate the color palette from an image with pywal16, then push it to every
# consumer (rofi, waybar, swaync, terminals, SDDM, Hyprland borders).
# Light mode (theme-mode.sh) asks pywal for a light scheme, except for terminals.
# Usage: apply-palette.sh IMAGE [SATURATION]
set -uo pipefail

# Picture.png is reused for video frames; never serve a stale cached scheme.
rm -f "$HOME"/.cache/wal/schemes/*Picture_png* 2>/dev/null
if [[ "$(cat "$HOME/.config/current/theme-mode" 2>/dev/null)" == light ]]; then
   # Terminals are translucent and stay dark: keep the dark scheme's terminal
   # files (alacritty import, sequences replayed by bash) over the light ones.
   wal -i "$1" -n -s -q --saturate "${2:-0.7}" -b 010101
   keep=$(mktemp -d)
   cp "$HOME/.cache/wal/colors-alacritty.toml" "$HOME/.cache/wal/sequences" "$keep/"
   wal -i "$1" -n -s -q --saturate "${2:-0.7}" -l
   mv -f "$keep/colors-alacritty.toml" "$keep/sequences" "$HOME/.cache/wal/"
   rmdir "$keep"
else
   wal -i "$1" -n -s -q --saturate "${2:-0.7}" -b 010101
fi
"$HOME/.local/share/custom/bin/wal-color-export.sh"
