# Background services and the apps that need system-level setup.
{
  imports = [
    ./docker.nix
    ./happ.nix
    ./web.nix
  ];

  services.happ = {
    enable = true;
    forceXwayland = true;
  };

  services.printing.enable = true;
  services.flatpak.enable = true;
}
