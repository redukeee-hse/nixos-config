#!/usr/bin/env bash
# Super+R: hide the Quickshell settings panel if it is open, else close the focused window.
if [[ "$(qs ipc call settings isOpen 2>/dev/null)" == true ]]; then
   qs ipc call settings hide
else
   hyprctl dispatch killactive
fi
