# Fills in defaults for local/settings.nix, so a settings file written for an
# older version keeps working when new options appear.
local:

let
  defaults = {
    fullName = local.username or "";
    timeZone = "Etc/UTC";
    locale = "en_US.UTF-8";
    extraLocaleSettings = { };
    keyboard = { };
    homeStateVersion = local.stateVersion;
    configDir = "/home/${local.username}/nixos-config";
    vpnApps = false;
    chatgpt = false;
  };
  keyboardDefaults = { layout = "us"; variant = ""; options = ""; };
  merged = defaults // local;
in
merged // {
  keyboard = keyboardDefaults // merged.keyboard;
}
