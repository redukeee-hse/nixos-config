# Sound, Bluetooth and power management.
{
  imports = [
    ./audio.nix
    ./bluetooth.nix
  ];

  services.power-profiles-daemon.enable = true;
}
