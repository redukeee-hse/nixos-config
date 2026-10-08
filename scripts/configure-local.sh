#!/usr/bin/env bash
# Writes local/settings.nix and local/hardware-configuration.nix for this
# machine. local/ is ignored by Git, so `update` never overwrites it.
#
#   ./scripts/configure-local.sh [USERNAME] [HOSTNAME] [options]
#
# Without arguments everything is taken from the running system: your user
# and host names, time zone, and from /etc/nixos the hardware file,
# stateVersion, locale and keyboard layout. Options override single values:
#   --user NAME  --host NAME  --full-name TEXT  --timezone ZONE
#   --locale LOCALE  --layout L  --variant V  --xkb-options O
#   --state-version VER  --home-state-version VER  --hardware FILE
#   --vpn-apps / --no-vpn-apps   install the apps that need a VPN in Russia
#                  (Claude, Spotify, Notion); asked when not given
#   --force        overwrite an existing local/settings.nix
set -euo pipefail

die() { echo "configure-local: $*" >&2; exit 1; }

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

etc_config=/etc/nixos/configuration.nix
# Value of `key = "value";` in /etc/nixos/configuration.nix, if any.
from_etc() {
  [[ -r $etc_config ]] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\([^\"]*\)\";.*/\1/p" "$etc_config" | head -n 1
}

username="" hostname="" full_name="" timezone="" locale="" layout="" variant="" xkb_options=""
state_version="" home_state_version="" hardware=/etc/nixos/hardware-configuration.nix force=0 vpn_apps=""
positional=()
while (( $# )); do
  case "$1" in
    --user) username="$2"; shift ;;
    --host) hostname="$2"; shift ;;
    --full-name) full_name="$2"; shift ;;
    --timezone) timezone="$2"; shift ;;
    --locale) locale="$2"; shift ;;
    --layout) layout="$2"; shift ;;
    --variant) variant="$2"; shift ;;
    --xkb-options) xkb_options="$2"; shift ;;
    --state-version) state_version="$2"; shift ;;
    --home-state-version) home_state_version="$2"; shift ;;
    --hardware) hardware="$2"; shift ;;
    --vpn-apps) vpn_apps=true ;;
    --no-vpn-apps) vpn_apps=false ;;
    --force) force=1 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) positional+=("$1") ;;
  esac
  shift
done
(( ${#positional[@]} <= 2 )) || die "usage: $0 [username] [hostname] [options]"
username="${username:-${positional[0]:-$(id -un)}}"
hostname="${hostname:-${positional[1]:-$(uname -n)}}"

[[ "$username" =~ ^[a-z_][a-z0-9_-]*$ && "$username" != root ]] || die "invalid regular username: $username"
[[ "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || die "invalid hostname: $hostname"

if [[ -e local/settings.nix ]] && (( ! force )); then
  die "local/settings.nix already exists; edit it, or pass --force to recreate it."
fi

if [[ -z $full_name ]]; then
  full_name="$(getent passwd "$username" | cut -d: -f5 | cut -d, -f1 || true)"
  full_name="${full_name:-$username}"
fi
if [[ -z $timezone ]]; then
  timezone="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
  [[ -n $timezone ]] || timezone="$(readlink /etc/localtime 2>/dev/null | sed -n 's|.*/zoneinfo/||p')"
  timezone="${timezone:-Etc/UTC}"
fi
locale="${locale:-$(from_etc i18n.defaultLocale)}"
locale="${locale:-en_US.UTF-8}"
layout="${layout:-$(from_etc layout)}"
layout="${layout:-us}"
variant="${variant:-$(from_etc variant)}"
xkb_options="${xkb_options:-$(from_etc options)}"
state_version="${state_version:-$(from_etc system.stateVersion)}"
# A wrong guess here can break stateful services, so never guess.
[[ -n $state_version ]] ||
  die "no system.stateVersion in $etc_config; pass --state-version with the NixOS release this system was first installed with."

if [[ -z $vpn_apps ]]; then
  vpn_apps=false
  if [[ -t 0 ]]; then
    echo "Some apps are blocked in Russia and need a VPN to download and use:"
    echo "  Claude Desktop, Claude Code, Spotify, Notion and Notion Calendar."
    read -r -p "Install them now? Your VPN must be on during the build. [y/N] " answer
    [[ $answer == [yY]* ]] && vpn_apps=true
    $vpn_apps || echo "Skipped. Add them later with: update --vpn-apps"
  fi
fi

# LC_* overrides that the NixOS installer writes into extraLocaleSettings.
extra_locale=""
if [[ -r $etc_config ]]; then
  extra_locale="$(sed -n 's/^[[:space:]]*\(LC_[A-Z]*\)[[:space:]]*=[[:space:]]*\("[^"]*"\);.*/    \1 = \2;/p' "$etc_config")"
fi

if [[ ! -e local/hardware-configuration.nix ]] || (( force )); then
  [[ -f $hardware ]] || die "missing $hardware; run nixos-generate-config on this machine first"
fi

nix_str() { printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\${/\\${/g')"; }

mkdir -p local
{
  echo "# This machine's settings; see local.example/settings.nix for every option."
  echo "# Ignored by Git and never touched by \`update\`. Apply changes with \`rebuild\`."
  echo "{"
  echo "  username = $(nix_str "$username");"
  echo "  fullName = $(nix_str "$full_name");"
  echo "  hostname = $(nix_str "$hostname");"
  echo
  echo "  timeZone = $(nix_str "$timezone");"
  echo "  locale = $(nix_str "$locale");"
  if [[ -n $extra_locale ]]; then
    echo "  extraLocaleSettings = {"
    echo "$extra_locale"
    echo "  };"
  else
    echo "  extraLocaleSettings = { };"
  fi
  echo
  echo "  keyboard = {"
  echo "    layout = $(nix_str "$layout");"
  echo "    variant = $(nix_str "$variant");"
  echo "    options = $(nix_str "$xkb_options");"
  echo "  };"
  echo
  echo "  # Claude, Spotify and Notion; they need a VPN in Russia. \`update --vpn-apps\` turns them on."
  echo "  vpnApps = $vpn_apps;"
  echo
  echo "  # The NixOS release this system was first installed with. Never change it."
  echo "  stateVersion = $(nix_str "$state_version");"
  [[ -z $home_state_version ]] || echo "  homeStateVersion = $(nix_str "$home_state_version");"
  echo "}"
} > local/settings.nix

if [[ ! -e local/hardware-configuration.nix ]] || (( force )); then
  cp -- "$hardware" local/hardware-configuration.nix
fi

echo "Wrote local/settings.nix for user $username on host $hostname:"
sed 's/^/  /' local/settings.nix
echo "Check it, then build and apply with ./scripts/rebuild.sh"
