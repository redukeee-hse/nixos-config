# Two fonts everywhere: Inter for the interface and text, JetBrains Mono Nerd
# Font for code and icons. Both cover Latin and Cyrillic. Noto Color Emoji only
# draws emoji.
{ pkgs, ... }:

{
  # Otherwise the graphical session adds DejaVu, Liberation, FreeFont, Gyre,
  # Unifont and Noto CJK on top.
  fonts.enableDefaultPackages = false;

  fonts.packages = with pkgs; [
    adwaita-fonts # Adwaita Sans, the title font of the notification cards
    inter
    # Icon font for the Quickshell surfaces (Hub, OSD, notifications).
    material-symbols
    # Orbit typefaces: the login theme bundles them, the lock screen
    # (hyprlock) and the Hub need them installed.
    montserrat
    eb-garamond
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
  ];
}
