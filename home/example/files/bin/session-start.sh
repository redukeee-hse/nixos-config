#!/usr/bin/env bash
set -euo pipefail
# Refresh both activation environments before GTK clients start.
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
# Hand the keyring that the SDDM login unlocked over to the session bus.
# Without this call it quits after a short while, and the first app asking
# for a secret starts a fresh, locked daemon that prompts for the password.
gnome-keyring-daemon --start --components=secrets >/dev/null || true
# Start the graphical session target (hypridle, nm-applet, battery-care).
systemctl --user start hyprland-session.target || true
# SwayNC is D-Bus activated through swaync.service; starting a second copy
# from exec-once races it and leaves the unit failed. Start it only here,
# once WAYLAND_DISPLAY is in the systemd environment.
# Only when SwayNC draws notifications (notifications.sh use swaync); by
# default the shell (Quickshell, Notifications.qml) owns them.
if [[ "$(cat "$HOME/.config/current/notification-daemon" 2>/dev/null)" == swaync ]]; then
   systemctl --user reset-failed swaync.service || true
   systemctl --user start swaync.service || true
fi
systemctl --user reset-failed xdg-desktop-portal-hyprland.service
systemctl --user restart xdg-desktop-portal-gtk.service xdg-desktop-portal-hyprland.service
systemctl --user restart xdg-desktop-portal.service
"$HOME/.local/share/custom/bin/wal-color-export.sh" || true
