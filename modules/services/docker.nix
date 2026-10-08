{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  # Start dockerd on the first docker command instead of at boot.
  virtualisation.docker.enableOnBoot = false;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
