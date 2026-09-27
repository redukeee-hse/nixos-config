#!/usr/bin/env bash
set -euo pipefail

if (( $# > 2 )); then
  echo "Usage: $0 [username] [hostname]" >&2
  exit 2
fi

username="${1:-$(id -un)}"
hostname="${2:-$(uname -n)}"
if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ || "$username" == root ]]; then
  echo "Invalid regular username: $username" >&2
  exit 2
fi
if [[ ! "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]]; then
  echo "Invalid hostname: $hostname" >&2
  exit 2
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
if [[ ! -d .git ]]; then
  echo "Run this script in a Git clone of the template." >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "The clone has uncommitted changes; use a clean clone." >&2
  exit 1
fi
if ! grep -q 'configuser' flake.nix; then
  echo "This clone has already been personalized." >&2
  exit 1
fi
if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
  echo "Missing /etc/nixos/hardware-configuration.nix; generate it on NixOS first." >&2
  exit 1
fi

while IFS= read -r -d '' path; do
  sed -i -e "s/configuser/$username/g" -e "s/confighost/$hostname/g" "$path"
done < <(git grep -l -z -e configuser -e confighost -- flake.nix hosts home modules)
cp -- /etc/nixos/hardware-configuration.nix hosts/example/hardware-configuration.nix

printf 'Configured local clone for user %s and host %s.\n' "$username" "$hostname"
printf 'Review git diff before building. Do not commit or push these machine-specific changes.\n'
