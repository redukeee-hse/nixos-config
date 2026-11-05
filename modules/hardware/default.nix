# Sound, Bluetooth, firmware updates and power management.
{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./firmware.nix
    ./huawei-audio.nix
  ];

  services.power-profiles-daemon.enable = true;
}
