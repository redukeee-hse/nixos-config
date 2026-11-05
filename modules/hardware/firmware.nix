# Firmware updates (UEFI/BIOS, SSD, Thunderbolt, peripherals) from LVFS.
# Drivers come with the kernel and nixpkgs, so `nix flake update` + rebuild
# covers them; fwupd covers the firmware side, like Huawei PC Manager did.
#   fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update
{ pkgs, ... }:
{
  services.fwupd.enable = true;

  # GUI front end for fwupd.
  environment.systemPackages = [ pkgs.gnome-firmware ];
}
