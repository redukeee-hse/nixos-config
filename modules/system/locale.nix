# Time zone, language and keyboard come from local/settings.nix.
{ settings, ... }:

{
  time.timeZone = settings.timeZone;
  i18n.defaultLocale = settings.locale;
  i18n.extraLocaleSettings = settings.extraLocaleSettings;

  # Used by the X11 login screen; Hyprland gets the same layout through
  # ~/.config/hyprland/keyboard.conf (home/example/modules/desktop.nix).
  services.xserver.xkb = {
    inherit (settings.keyboard) layout variant options;
  };
}
