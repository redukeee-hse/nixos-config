# The BlueZ daemon plus blueman's system D-Bus service.
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # No pairing agent runs in the Hyprland session, so BlueZ would keep the
    # adapter non-bondable and pairings would not store a link key.
    settings.General.AlwaysPairable = true;
  };
  services.blueman.enable = true;
}
