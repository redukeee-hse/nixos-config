{ lib, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-color-emoji
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
