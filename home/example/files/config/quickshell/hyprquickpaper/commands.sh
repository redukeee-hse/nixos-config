#!/usr/bin/env bash
# Called by the picker with the chosen image: set it and regenerate the palette.
img="$1"
[[ -f "$img" ]] || { echo "commands.sh: not a file: $img" >&2; exit 1; }

link="$HOME/.config/current/Wallpapers/Picture.png"
[[ -e "$link" && ! -L "$link" ]] && rm -f "$link"
ln -nsf "$img" "$link"
~/.local/share/custom/bin/set-wallpaper.sh "$img"
~/.local/share/custom/bin/apply-palette.sh "$img" 0.7
