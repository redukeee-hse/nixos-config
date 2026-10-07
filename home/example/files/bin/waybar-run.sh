#!/usr/bin/env bash
# Keep waybar alive across crashes. Its audio module aborts when PipeWire
# restarts (e.g. during nixos-rebuild switch), and exec-once never restarts it.
# Only a crash (signal 6/11 → exit 134/139) restarts it; a normal kill
# (pkill waybar → 143) or clean exit stops the loop.
while true; do
   waybar "$@"
   rc=$?
   [[ $rc == 134 || $rc == 139 ]] || exit "$rc"
   sleep 1
done
