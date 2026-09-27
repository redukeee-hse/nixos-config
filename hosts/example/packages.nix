# System-wide packages and services for this host.
{ pkgs, ... }:

{
  services.happ = {
    enable = true;
    forceXwayland = true;
  };

  environment.systemPackages = with pkgs; [
    # System and session integration
    docker
    docker-compose
    gparted
    hypridle
    hyprlock
    openvpn
    uwsm
    xdg-desktop-portal-hyprland

    # Audio stack and diagnostic tools
    alsa-utils
    pipewire
    pulseaudioFull
    wireplumber
  ];
}
