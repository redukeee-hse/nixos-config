# Your machine. scripts/configure-local.sh writes local/settings.nix from
# this template; edit that copy, never this file. local/ is ignored by Git
# and `update` never touches it.
{
  username = "alice";          # your login name
  fullName = "Alice";          # shown on the login screen and in GNOME apps
  hostname = "nixos";

  timeZone = "Etc/UTC";        # e.g. "Europe/Berlin"; see `timedatectl list-timezones`
  locale = "en_US.UTF-8";
  # Formats (dates, numbers, paper) from another locale, e.g.
  # extraLocaleSettings = { LC_TIME = "de_DE.UTF-8"; LC_MEASUREMENT = "de_DE.UTF-8"; };
  extraLocaleSettings = { };

  keyboard = {
    layout = "us";             # several layouts: "us,de"
    variant = "";              # one per layout: ","
    options = "";              # switch layouts: "grp:alt_shift_toggle"
  };

  # Apps that are blocked in Russia and need a VPN to download or use:
  # Claude Desktop, Claude Code, Spotify, Notion and Notion Calendar.
  # Turn on with `update --vpn-apps` (or set true here and run `rebuild`)
  # while your VPN is connected.
  vpnApps = false;
  # ChatGPT desktop as well (needs vpnApps). Its installer can't be fetched
  # automatically: download chatgpt_amd64.deb from OpenAI, then run
  # `nix-store --add-fixed sha256 ~/Downloads/chatgpt_amd64.deb`.
  chatgpt = false;

  # The NixOS release your system was FIRST installed with (it is in
  # /etc/nixos/configuration.nix). Never change it afterwards.
  stateVersion = "26.05";
  # Same for Home Manager; defaults to stateVersion.
  # homeStateVersion = "26.05";
}
