# Virtual machines, as in Ryoku (qemu + OVMF + virgl): libvirt with
# virt-manager; UEFI firmware and 3D acceleration come with QEMU in NixOS.
{ settings, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.${settings.username}.extraGroups = [ "libvirtd" ];
}
