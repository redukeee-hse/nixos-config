{ lib, pkgs, settings, ... }:

let
  localPackages = import ../../../packages { inherit pkgs; };
in
{
  # Apps whose downloads or services are blocked in Russia, so a build there
  # needs a VPN. Off by default; see vpnApps in local.example/settings.nix.
  home.packages = lib.optionals settings.vpnApps [
    localPackages.claude-desktop
    localPackages.claude-code
    pkgs.spotify
  ] ++ lib.optional (settings.vpnApps && settings.chatgpt) localPackages.chatgpt
  ++ (with pkgs; [
    # Desktop and launchers
    alacritty
    github-desktop
    nautilus
    swaynotificationcenter
    telegram-desktop
    vscode
    rofi
    waybar
    eww
    mission-center
    quickshell

    # Shell and terminal tools
    fastfetch
    fd
    libqalculate
    starship
    trash-cli
    ttyper

    # Desktop helpers used by Hyprland and custom scripts
    awww
    brightnessctl
    ffmpeg
    hyprsunset
    grim
    imagemagick
    jq
    libnotify
    mpvpaper
    networkmanagerapplet
    # GPU load for the Waybar GPU module; use nvtopPackages.amd/.nvidia/.full for other GPUs
    nvtopPackages.intel
    papirus-icon-theme
    playerctl
    pywal16
    slurp
    wl-clipboard

    # Appearance
    bibata-cursors
  ]);
}
