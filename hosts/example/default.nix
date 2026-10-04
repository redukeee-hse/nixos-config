# Example host. Everything that is not specific to one machine lives in
# ../../modules; scripts/configure-local.sh fills in your user and host names.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/services
  ];

  networking.hostName = "confighost";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Keep it at the release of YOUR first install.
  system.stateVersion = "25.05";
}
