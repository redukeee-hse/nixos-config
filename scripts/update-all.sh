#!/usr/bin/env bash
# For working on the configuration itself: updates every version pin at once
# and applies the result. Flake inputs (nixpkgs with the kernel and drivers,
# home-manager, zen), the local packages in packages/, then a rebuild and
# firmware updates through fwupd.
#
# This edits tracked files (flake.lock, packages/). If you only use the
# config, run `update` instead: it would set such edits aside as a patch.
#
# Usage:
#   scripts/update-all.sh            update everything
#   scripts/update-all.sh --check    only show what is outdated
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

if [[ "${1:-}" == "--check" ]]; then
  step "Local packages (packages/)"
  scripts/update-apps.py --check
  step "Firmware (fwupd)"
  fwupdmgr refresh --force >/dev/null || true
  fwupdmgr get-updates || true
  exit 0
fi

step "Flake inputs: nixpkgs (kernel, drivers, apps), home-manager, zen"
nix flake update

step "Local packages (packages/)"
# One failing package (an unreachable mirror, say) must not cancel the
# rebuild, or the packages that did update would never get installed.
apps_failed=0
scripts/update-apps.py || apps_failed=1

step "Rebuilding the system"
scripts/rebuild.sh switch

step "Firmware (fwupd)"
fwupdmgr refresh --force || true
# get-updates exits with 2 when there is nothing to update.
if fwupdmgr get-updates; then
  fwupdmgr update
fi

step "Done"
git -c color.status=always status --short
if (( apps_failed )); then
  printf '\n\033[1;33mSome packages could not be checked (see ✗ above); retry with scripts/update-apps.py <name>\033[0m\n'
  exit 1
fi
