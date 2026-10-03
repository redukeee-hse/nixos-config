#!/usr/bin/env bash
# Open a terminal window in the running Alacritty daemon (no process start or GPU
# init, so it maps in ~0.1 s instead of ~0.3 s). Falls back to a standalone
# Alacritty when the daemon isn't up.
alacritty msg create-window "$@" 2>/dev/null || exec alacritty "$@"
