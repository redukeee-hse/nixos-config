#!/usr/bin/env bash
# Open a terminal. Kitty runs a single instance per session (-1): later windows
# map in about 0.1 s without a new process. Arguments are kitty's own, e.g.
#   term.sh --class=FloatingTermS --directory=~ fish -C fastfetch
exec kitty -1 --instance-group=hypr "$@"
