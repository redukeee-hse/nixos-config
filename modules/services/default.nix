# Background services and the apps that need system-level setup.
{
  imports = [
    ./dev-services.nix
    ./docker.nix
    ./happ.nix
    ./observability.nix
    ./web.nix
  ];

  services.happ = {
    enable = true;
    forceXwayland = true;
  };
}
