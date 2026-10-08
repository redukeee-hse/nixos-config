# Two fonts everywhere: Inter for the interface and text, JetBrains Mono Nerd
# Font for code and icons. Both cover Latin and Cyrillic. Noto Color Emoji only
# draws emoji.
{ pkgs, ... }:

{
  # Otherwise the graphical session adds DejaVu, Liberation, FreeFont, Gyre,
  # Unifont and Noto CJK on top.
  fonts.enableDefaultPackages = false;

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
  ];
}
