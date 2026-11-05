#!/usr/bin/env bash
# Called by the picker with the chosen image: set it and regenerate the palette.
# The picker lists ~/.config/current/wallpaper-dir, a link that changes with
# the light/dark mode, so resolve it to the real file first.
img=$(readlink -e "$1")
[[ -f "$img" ]] || { echo "commands.sh: not a file: $1" >&2; exit 1; }

link="$HOME/.config/current/Wallpapers/Picture.png"
[[ -e "$link" && ! -L "$link" ]] && rm -f "$link"
ln -nsf "$img" "$link"
# Remember it as the wallpaper of the current mode for theme-mode.sh.
ln -nsf "$img" "$HOME/.config/current/wallpaper-$(~/.local/share/custom/bin/theme-mode.sh get)"
~/.local/share/custom/bin/set-wallpaper.sh "$img"
~/.local/share/custom/bin/apply-palette.sh "$img" 0.7
