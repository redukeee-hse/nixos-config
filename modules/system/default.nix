# Base system: Nix itself, boot, networking, locale and users.
{
  imports = [
    ./boot.nix
    ./commands.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./users.nix
  ];
}
