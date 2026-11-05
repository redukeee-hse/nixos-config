#!/usr/bin/env bash
# Cleans the Nix store: keeps the last two generations of the system,
# home-manager and the user profile, deletes the rest and drops the old
# entries from the GRUB menu. Pinned gcroots are left alone.
#
# Usage:
#   scripts/clean.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP=2

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
free() { df -h --output=avail /nix | tail -1 | tr -d ' '; }

before="$(free)"

step "System: keeping the last $KEEP generations"
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations "+$KEEP"
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations

step "home-manager and the user profile"
for p in "$HOME/.local/state/nix/profiles/home-manager" "$HOME/.local/state/nix/profiles/profile"; do
  [[ -e "$p" ]] && nix-env --profile "$p" --delete-generations "+$KEEP"
done

# ./result from `nix build` keeps an old system build in the store.
rm -f "$REPO/result"

step "Garbage collection"
sudo nix-store --gc

step "Updating the boot menu"
sudo /run/current-system/bin/switch-to-configuration boot

step "Done: free space on /nix was $before, now $(free)"
