{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Secret Service (libsecret) for Electron apps such as Claude Desktop;
  # the SDDM login unlocks it.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # hyprlock checks the password through its own PAM service.
  security.pam.services.hyprlock = { };

  # GTK portal next to the Hyprland one: file pickers and the color-scheme
  # setting that Happ's Qt theme reads.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # No nm-applet: Wi-Fi lives in the Hub (Network) and Waybar; with the
  # graphical session running it would add a second Wi-Fi icon to the tray.
  programs.nm-applet.enable = false;
  # No idle timeouts; hypridle only locks (lock.sh) before sleep.
  services.hypridle.enable = true;
  environment.localBinInPath = true;

  # monitor-hotplug.sh switches to another VT and back to light an external
  # monitor that Hyprland left dark; chvt alone, no password.
  security.sudo.extraRules = [{
    users = [ "reduke" ];
    commands = [{
      command = "/run/current-system/sw/bin/chvt";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.systemPackages = with pkgs; [
    gparted
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland
  ];
}
