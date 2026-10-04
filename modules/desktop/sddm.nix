{ config, pkgs, ... }:
let
  westonConfig = (pkgs.formats.ini { }).generate "sddm-weston.ini" {
    libinput = {
      accel-speed = 0.2;
      enable-tap = config.services.libinput.mouse.tapping;
      left-handed = config.services.libinput.mouse.leftHanded;
    };
    keyboard = {
      keymap_layout = "us";
      keymap_options = "";
    };
  };

  theme = pkgs.runCommand "nixos-sddm-theme" { } ''
    themeDir="$out/share/sddm/themes/nixos"
    mkdir -p "$themeDir"
    cp ${./sddm-theme/Main.qml} "$themeDir/Main.qml"
    cp ${./sddm-theme/metadata.desktop} "$themeDir/metadata.desktop"
    ln -s /var/lib/nixos-sddm/background.jpg "$themeDir/background.jpg"
    ln -s /var/lib/nixos-sddm/theme.conf "$themeDir/theme.conf"
  '';
in {
  environment.systemPackages = [ theme ];

  systemd.tmpfiles.rules = [
    "d /var/lib/nixos-sddm 0755 configuser users -"
  ];

  system.activationScripts.initializeNixOSSddmTheme = {
    deps = [ "users" ];
    text = ''
      install -d -m 0755 -o configuser -g users /var/lib/nixos-sddm
      if [[ ! -e /var/lib/nixos-sddm/background.jpg ]]; then
        install -m 0644 -o configuser -g users \
          ${./assets/login-background.jpg} \
          /var/lib/nixos-sddm/background.jpg
      fi
      if [[ ! -e /var/lib/nixos-sddm/theme.conf ]]; then
        install -m 0644 -o configuser -g users \
          ${./sddm-theme/theme.conf} \
          /var/lib/nixos-sddm/theme.conf
      fi
    '';
  };

  # Standalone graphical login straight into Hyprland.
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "nixos";
    extraPackages = [ theme ];
    wayland.compositorCommand =
      "${pkgs.weston}/bin/weston --shell=kiosk -c ${westonConfig}";
    settings.Users.HideUsers = "root";
    # A stable /run/current-system URL can reuse stale QML compiled before
    # a rebuild: Nix store files also share a normalized modification time.
    settings.Theme.ThemeDir = "${theme}/share/sddm/themes";
    settings.General.GreeterEnvironment = "QML_DISABLE_DISK_CACHE=1";
  };
}
