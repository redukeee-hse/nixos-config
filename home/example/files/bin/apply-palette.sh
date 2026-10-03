#!/usr/bin/env bash
# Generate the color palette from an image with pywal16, then push it to every
# consumer (waybar, walker, swaync, terminals, SDDM, Hyprland borders).
# Usage: apply-palette.sh IMAGE [SATURATION]
set -uo pipefail

# Picture.png is reused for video frames; never serve a stale cached scheme.
rm -f "$HOME"/.cache/wal/schemes/*Picture_png* 2>/dev/null
wal -i "$1" -n -s -q --saturate "${2:-0.7}" -b 010101
"$HOME/.local/share/custom/bin/wal-color-export.sh"
