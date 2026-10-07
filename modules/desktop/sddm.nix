{ pkgs, settings, ... }:
let
  user = settings.username;

  # Same pointer as in Hyprland. The greeter can't see the user's home
  # profile, so the theme is passed to it explicitly. X11 doesn't scale the
  # screen, so the size matches Hyprland's 16 at its auto (~1.5x) scale.
  cursorTheme = "Bibata-Modern-Classic";
  cursorSize = 24;
  cursorPath = "${pkgs.bibata-cursors}/share/icons";

  theme = pkgs.runCommand "nixos-sddm-theme" { } ''
    themeDir="$out/share/sddm/themes/nixos"
    mkdir -p "$themeDir"
    substitute ${./sddm-theme/Main.qml} "$themeDir/Main.qml" \
      --replace-fail "@defaultUser@" ${user}
    cp ${./sddm-theme/metadata.desktop} "$themeDir/metadata.desktop"
    ln -s /var/lib/nixos-sddm/background.jpg "$themeDir/background.jpg"
    ln -s /var/lib/nixos-sddm/theme.conf "$themeDir/theme.conf"
  '';
in {
  environment.systemPackages = [ theme ];

  systemd.tmpfiles.rules = [
    "d /var/lib/nixos-sddm 0755 ${user} users -"
  ];

  system.activationScripts.initializeNixOSSddmTheme = {
    deps = [ "users" ];
    text = ''
      install -d -m 0755 -o ${user} -g users /var/lib/nixos-sddm
      if [[ ! -e /var/lib/nixos-sddm/background.jpg ]]; then
        install -m 0644 -o ${user} -g users \
          ${./assets/login-background.jpg} \
          /var/lib/nixos-sddm/background.jpg
      fi
      if [[ ! -e /var/lib/nixos-sddm/theme.conf ]]; then
        install -m 0644 -o ${user} -g users \
          ${./sddm-theme/theme.conf} \
          /var/lib/nixos-sddm/theme.conf
      fi
    '';
  };

  # Standalone graphical login straight into Hyprland.
  services.displayManager.defaultSession = "hyprland";
  # The login screen runs on X11: under weston (kiosk shell) the pointer can
  # be invisible on some laptops. Hyprland itself still starts on Wayland.
  services.xserver.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "nixos";
    extraPackages = [ theme ];
    settings.Users.HideUsers = "root";
    # A stable /run/current-system URL can reuse stale QML compiled before
    # a rebuild: Nix store files also share a normalized modification time.
    settings.Theme.ThemeDir = "${theme}/share/sddm/themes";
    settings.General.GreeterEnvironment = builtins.concatStringsSep "," [
      "QML_DISABLE_DISK_CACHE=1"
      "XCURSOR_PATH=${cursorPath}"
      "XCURSOR_THEME=${cursorTheme}"
      "XCURSOR_SIZE=${toString cursorSize}"
    ];
  };
}
