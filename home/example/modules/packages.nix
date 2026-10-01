{ pkgs, zen-browser, nixpkgs-walker, ... }:

let
  localPackages = import ../../../packages { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    localPackages.claude-desktop
    localPackages.claude-code
    localPackages.chatgpt
    (zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta.override {
      extraPolicies = {
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        Preferences = builtins.mapAttrs (_: value: { Value = value; Status = "default"; }) {
          "ui.systemUsesDarkTheme" = 1;
          "browser.theme.content-theme" = 0;
          "browser.theme.toolbar-theme" = 0;
          "zen.view.compact.enable" = true;
          "zen.view.compact.hide-tabbar" = true;
          "zen.view.compact.hide-toolbar" = false;
          "font.name.sans-serif.x-western" = "Noto Sans";
          "font.name.sans-serif.x-cyrillic" = "Noto Sans";
          "font.name.serif.x-western" = "Noto Serif";
          "font.name.serif.x-cyrillic" = "Noto Serif";
          "browser.tabs.unloadOnLowMemory" = true;
        };
        ExtensionSettings."uBlock0@raymondhill.net" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    })

    # Desktop and launchers
    alacritty
    blueman
    github-desktop
    nautilus
    rofi
    swaynotificationcenter
    spotify
    telegram-desktop
    vscode
    nixpkgs-walker.legacyPackages.${pkgs.stdenv.hostPlatform.system}.walker
    waybar

    # Shell and terminal tools
    btop
    cava
    fastfetch
    fd
    libqalculate
    starship
    ttyper
    unimatrix
    yazi

    # Desktop helpers used by Hyprland and custom scripts
    awww
    brightnessctl
    ffmpeg
    grim
    jq
    libnotify
    mpvpaper
    networkmanagerapplet
    networkmanager_dmenu
    pamixer
    papirus-icon-theme
    pavucontrol
    playerctl
    pywal16
    slurp
    wf-recorder
    wl-clipboard

    # Appearance
    bibata-cursors
  ];
}
