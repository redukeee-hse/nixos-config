# Zen is the main browser; Notion web apps run in it too (notion.nix).
{ pkgs, zen-browser, ... }:

let
  zenPackages = zen-browser.packages.${pkgs.stdenv.hostPlatform.system};

  # Policies must live in the unwrapped package: Zen resolves its binary
  # through the wrapper's symlink and only reads distribution/policies.json
  # next to the real executable, so `beta.override { extraPolicies }` is
  # silently ignored. Wrap it the same way the flake's wrap-zen.nix does.
  zenUnwrapped = (zenPackages.beta-unwrapped.override {
    extraPolicies = {
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      Preferences = builtins.mapAttrs (_: value: { Value = value; Status = "default"; }) {
        # Browser UI and pages follow the system light/dark mode (theme-mode.sh,
        # Super+Shift+Space) through the settings portal.
        "browser.theme.content-theme" = 2;
        "browser.theme.toolbar-theme" = 2;
        "zen.view.compact.enable" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = false;
        "font.name.sans-serif.x-western" = "Inter";
        "font.name.sans-serif.x-cyrillic" = "Inter";
        "font.name.serif.x-western" = "Inter";
        "font.name.serif.x-cyrillic" = "Inter";
        "browser.tabs.unloadOnLowMemory" = true;
        # Hide the "Pop out this video" hover button; PiP stays in the context menu.
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
      } // {
        # "Website appearance" was set to Light in the profile, which forced
        # pages light in dark mode. Reset it to follow the system on every start.
        "layout.css.prefers-color-scheme.content-override" = { Value = 2; Status = "user"; };
      };
      ExtensionSettings."uBlock0@raymondhill.net" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      };
      # Removes the earlier wallpaper-theming attempt from every profile.
      ExtensionSettings."pywalfox@frewacom.org".installation_mode = "blocked";
      # Removes Dark Reader from every profile: sites without a dark theme of
      # their own stay light.
      ExtensionSettings."addon@darkreader.org".installation_mode = "blocked";
    };
  });

  zen = pkgs.wrapFirefox
    (zenUnwrapped // { version = zenUnwrapped.firefoxVersion or "9999"; })
    {
      inherit (zenUnwrapped) version;
      icon = "zen-browser";
    };
in
{
  home.packages = [ zen ];
}
