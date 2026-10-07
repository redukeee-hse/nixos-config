#!/usr/bin/env bash
# Builds the configuration and applies it, like nixos-rebuild.
#
#   rebuild            build and switch to it now
#   rebuild build      only build; changes nothing
#   rebuild boot       switch on the next boot
#
# local/ is ignored by Git, and a git+file flake (`--flake .#example`) only
# sees tracked files, so the flake is passed as a path: reference.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"
action="${1:-switch}"
(( $# )) && shift

if [[ ! -f "$repo_dir/local/settings.nix" ]]; then
  echo "rebuild: $repo_dir/local/settings.nix is missing; run $repo_dir/scripts/configure-local.sh first." >&2
  exit 1
fi
if (( EUID == 0 )); then
  echo "rebuild: run this as your normal user; it asks for sudo itself." >&2
  exit 1
fi

cd "$repo_dir"
exec sudo env NIX_CONFIG='experimental-features = nix-command flakes' \
  nixos-rebuild "$action" --flake "path:$repo_dir#example" "$@"
