#!/usr/bin/env bash
# Updates this configuration to the latest version of the template and
# applies it. Your settings in local/ are kept as they are.
#
#   update               download the update, rebuild and switch to it
#   update --no-switch   only update the files; apply later with `rebuild`
#   update --yes         don't ask before setting aside edits to tracked files
#   update --vpn-apps    also install the apps that need a VPN in Russia
#                        (Claude, Spotify, Notion); keep the VPN on
#   update --no-vpn-apps remove them again
#
# Edits to files tracked by Git would block the update. They are saved as a
# patch in local/backups/ and reverted, so put your own options into
# local/configuration.nix and local/home.nix instead. Your own commits are
# kept and replayed on top of the new version.
#
# Installs from before local/ existed (personalized by the old
# configure-local.sh) are migrated: names, stateVersion, time zone, keyboard
# and the hardware file move into local/ first.
set -euo pipefail

branch=main
switch=1
assume_yes=0
vpn_apps=""
for arg in "$@"; do
  case "$arg" in
    --no-switch) switch=0 ;;
    -y|--yes) assume_yes=1 ;;
    --vpn-apps) vpn_apps=true ;;
    --no-vpn-apps) vpn_apps=false ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "update: unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

die() { echo "update: $*" >&2; exit 1; }
say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
ask() {
  (( assume_yes )) && return 0
  [[ -t 0 ]] || die "$1 Run with --yes to confirm without a prompt."
  local answer
  read -r -p "$1 [y/N] " answer
  [[ $answer == [yY]* ]]
}

(( EUID != 0 )) || die "run this as your normal user; it asks for sudo itself."

# The repository this script belongs to, or ~/nixos-config when it is run
# from elsewhere (the one-time bootstrap for old installs, see README).
self_repo="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"
if [[ -f $self_repo/flake.nix && -d $self_repo/.git ]]; then
  repo="$self_repo"
else
  repo="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
fi
[[ -d $repo/.git ]] || die "$repo is not a Git clone of the configuration."
cd "$repo"

[[ -z $(git ls-files --unmerged) && ! -d .git/rebase-merge && ! -d .git/rebase-apply ]] ||
  die "a merge or rebase is in progress in $repo; finish or abort it first."

# --- Migrate an install personalized in place by the old configure-local.sh.
migrate=()
if [[ ! -f local/settings.nix ]]; then
  old_user="$(sed -n 's/.*home-manager\.users\.\([a-z_][a-z0-9_-]*\) = import .*/\1/p' flake.nix | head -n 1)"
  if [[ -n $old_user && $old_user != configuser ]]; then
    say "Moving your settings from the old layout into local/"
    value() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\([^\"]*\)\";.*/\1/p" "$2" 2>/dev/null | head -n 1; }
    old_host="$(value networking.hostName hosts/example/default.nix)"
    migrate=(--user "$old_user")
    [[ -z $old_host ]] || migrate+=(--host "$old_host")
    for pair in \
      "--state-version system.stateVersion hosts/example/default.nix" \
      "--home-state-version home.stateVersion home/example/default.nix" \
      "--timezone time.timeZone modules/system/locale.nix" \
      "--locale i18n.defaultLocale modules/system/locale.nix" \
      "--layout layout modules/system/locale.nix" \
      "--variant variant modules/system/locale.nix" \
      "--xkb-options options modules/system/locale.nix"; do
      read -r flag key file <<<"$pair"
      found="$(value "$key" "$file")"
      [[ -z $found ]] || migrate+=("$flag" "$found")
    done
    mkdir -p local
    # The old layout kept the real hardware file in the clone.
    if ! git diff --quiet HEAD -- hosts/example/hardware-configuration.nix 2>/dev/null; then
      cp hosts/example/hardware-configuration.nix local/hardware-configuration.nix
    fi
    echo "  found: ${migrate[*]}"
  fi
fi

# --- Set aside edits to tracked files; they would block the update.
if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
  echo "These tracked files have local edits:"
  git status --short --untracked-files=no | sed 's/^/  /'
  if (( ${#migrate[@]} )); then
    echo "Most of them are your names and hardware from the old setup, which now live in local/."
  fi
  backup="local/backups/update-$(date +%Y%m%d-%H%M%S).patch"
  echo "They will be saved to $backup and reverted."
  echo "To keep custom options, move them into local/configuration.nix or local/home.nix afterwards."
  ask "Continue?" || die "nothing changed."
  mkdir -p local/backups
  git diff HEAD --binary > "$backup"
  git reset --quiet --hard HEAD
fi

# --- Download and apply the new version of the template.
say "Downloading the latest version"
old_head="$(git rev-parse HEAD)"
git fetch --quiet origin "$branch"
if git merge-base --is-ancestor HEAD FETCH_HEAD; then
  git merge --quiet --ff-only FETCH_HEAD
elif git merge-base --is-ancestor FETCH_HEAD HEAD; then
  : # Only local commits on top of the latest version.
else
  say "Replaying your own commits on top of the new version"
  if ! git rebase --quiet FETCH_HEAD >/dev/null 2>&1; then
    git rebase --abort
    die "your commits conflict with the update; nothing changed. Resolve with: cd $repo && git rebase origin/$branch"
  fi
fi

new_commits="$(git log --oneline --no-decorate "$old_head..FETCH_HEAD")"
if [[ -z $new_commits ]]; then
  echo "Already up to date."
else
  echo "New changes:"
  sed 's/^/  /' <<<"$new_commits"
fi

# --- Write local/ for migrated or brand-new clones with the new script.
if [[ ! -f local/settings.nix ]]; then
  say "Creating local/settings.nix"
  case $vpn_apps in
    true) migrate+=(--vpn-apps) ;;
    false) migrate+=(--no-vpn-apps) ;;
  esac
  "$repo/scripts/configure-local.sh" "${migrate[@]}"
elif [[ -n $vpn_apps ]]; then
  # Settings files from before vpnApps existed lack the line; add it.
  if grep -q '^[[:space:]]*vpnApps[[:space:]]*=' local/settings.nix; then
    sed -i "s/^\([[:space:]]*vpnApps[[:space:]]*=[[:space:]]*\)[a-z]*;/\1$vpn_apps;/" local/settings.nix
  else
    sed -i "\$s/^}/  vpnApps = $vpn_apps;\n}/" local/settings.nix
  fi
  if [[ $vpn_apps == true ]]; then
    say "Turned on the VPN apps in local/settings.nix; keep your VPN connected"
  else
    say "Turned off the VPN apps in local/settings.nix"
  fi
fi

if (( switch )); then
  say "Building and switching to the new system"
  exec "$repo/scripts/rebuild.sh" switch
else
  echo "Files updated. Apply them with: rebuild"
fi
