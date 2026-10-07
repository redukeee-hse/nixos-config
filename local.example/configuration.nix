# Optional: copy to local/configuration.nix for your own NixOS options.
# They are merged with the template, so you don't have to edit tracked files
# (which `update` would ask to reset). Use lib.mkForce to override a value
# the template already sets.
{ lib, pkgs, ... }:

{
  # environment.systemPackages = with pkgs; [ gimp ];
  # boot.initrd.kernelModules = [ "amdgpu" ];   # sharp boot splash on AMD
  # boot.loader.grub.useOSProber = lib.mkForce false;
}
