#!/usr/bin/env bash
set -euo pipefail
# Refresh both activation environments before GTK clients start.
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
systemctl --user reset-failed xdg-desktop-portal-hyprland.service
systemctl --user restart xdg-desktop-portal-gtk.service xdg-desktop-portal-hyprland.service
systemctl --user restart xdg-desktop-portal.service
"$HOME/.local/share/custom/bin/wal-color-export.sh" || true
