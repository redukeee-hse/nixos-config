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

  # AmneziaWG: awg / awg-quick on top of the userspace amneziawg-go, since
  # the kernel module does not build against kernel 7.3 yet. Tunnels are
  # brought up by hand: sudo awg-quick up /path/to/tunnel.conf
  environment.systemPackages = with pkgs; [
    amneziawg-tools
    amneziawg-go
  ];

  # AmneziaVPN GUI client (also imports AmneziaWG configs and vpn:// keys).
  # Its AmneziaVPN systemd service does the privileged tunnel setup.
  programs.amnezia-vpn.enable = true;
}
