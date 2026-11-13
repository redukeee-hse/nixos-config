{ lib, pkgs, settings, ... }:

let
  localPackages = import ../../../packages { inherit pkgs; };

  # VS Code 1.144 moved its bundled ripgrep to @vscode/ripgrep-universal, but
  # nixpkgs still runs `rm` on the old path and the build fails. Recreate the
  # old path so that step passes, and point the new one at nixpkgs' ripgrep.
  # Drop this once nixpkgs builds vscode 1.144+ on its own.
  vscode = pkgs.vscode.overrideAttrs (old: {
    postPatch = ''
      oldRg=resources/app/node_modules/@vscode/ripgrep/bin/rg
      newRg=resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg
      if [ ! -e "$oldRg" ] && [ -e "$newRg" ]; then
        mkdir -p "$(dirname "$oldRg")"
        touch "$oldRg"
        ln -sf ${pkgs.ripgrep}/bin/rg "$newRg"
      fi
    '' + old.postPatch;
  });
in
{
  # Apps whose downloads or services are blocked in Russia, so a build there
  # needs a VPN. Off by default; see vpnApps in local.example/settings.nix.
  home.packages = lib.optionals settings.vpnApps [
    localPackages.claude-desktop
    localPackages.claude-code
    pkgs.spotify
    pkgs.discord
  ] ++ lib.optional (settings.vpnApps && settings.chatgpt) localPackages.chatgpt
  ++ (with pkgs; [
    # Desktop and launchers
    alacritty
    kitty
    github-desktop
    nautilus
    swaynotificationcenter
    telegram-desktop
    vscode
    # Launcher with calculator and emoji modes (Super+Space, Ctrl+Tab).
    (rofi.override { plugins = [ rofi-calc rofi-emoji ]; })
    libqalculate
    waybar
    eww
    mission-center
    quickshell

    # Shell and terminal tools
    fastfetch
    fd
    ripgrep
    eza
    bat
    fzf
    zoxide
    yazi
    lazygit
    btop
    starship
    trash-cli
    socat
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
    # GPU load for the Waybar GPU module; use nvtopPackages.amd/.nvidia/.full for other GPUs
    nvtopPackages.intel
    papirus-icon-theme
    playerctl
    pywal16
    slurp
    wl-clipboard

    # Clipboard history and the capture tool (clipboard.sh, capture.sh)
    cliphist
    satty
    hyprpicker
    (tesseract.override { enableLanguages = [ "eng" "rus" ]; })
    zbar
    wf-recorder

    # Offline voice typing (dictate.sh, Super+Alt+D)
    whisper-cpp
    wtype

    # Appearance
    bibata-cursors
    # Adwaita-dark for GTK3 apps; GTK3 only ships the light Adwaita built in.
    gnome-themes-extra
  ]);
}
