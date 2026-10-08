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

  programs.nm-applet.enable = true;
  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    gparted
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland
  ];
}
