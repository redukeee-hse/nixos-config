{ pkgs, ... }:

{
  networking.networkmanager.enable = true;
  # Nothing here needs the network before login; this saves a few seconds of boot.
  systemd.services.NetworkManager-wait-online.enable = false;

  services.resolved.enable = true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 22 ];  # HTTP/HTTPS and SSH
}
