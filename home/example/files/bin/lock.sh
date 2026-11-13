#!/usr/bin/env bash
# Lock the screen in the chosen style (Hub > Appearance > Lock screen):
# orbit (hyprlock.conf, like the login screen) or classic.
pidof hyprlock >/dev/null && exit 0
if [[ "$(cat "$HOME/.config/current/lock-style" 2>/dev/null)" == classic ]]; then
   exec hyprlock -c "$HOME/.config/hypr/hyprlock-classic.conf"
fi
exec hyprlock
