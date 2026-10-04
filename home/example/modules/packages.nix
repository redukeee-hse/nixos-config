{ pkgs, ... }:

let
  localPackages = import ../../../packages { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    localPackages.claude-desktop
    localPackages.claude-code
    localPackages.chatgpt

    # Desktop and launchers
    alacritty
    github-desktop
    nautilus
    swaynotificationcenter
    spotify
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
  ];
}
