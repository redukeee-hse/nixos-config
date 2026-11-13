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

  programs.nm-applet.enable = true;
  # Idle dimming, locking (lock.sh) and suspend; hypridle.conf has the times.
  services.hypridle.enable = true;
  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    gparted
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland
  ];
}
