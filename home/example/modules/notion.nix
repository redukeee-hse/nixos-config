{ config, lib, pkgs, settings, ... }:

let
  # Notion ships no Linux desktop app (nixpkgs' notion-app is macOS-only and
  # notion-app-enhanced is a dead 2021 Electron build), so both run as web
  # apps in Zen with dedicated profiles. A separate Wayland app id keeps their
  # windows apart from the main browser and lets launchers match the icon.
  webApp = name: url: pkgs.writeShellScriptBin name ''
    profile_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/${name}-profile"
    mkdir -p "$profile_dir"
    exec /etc/profiles/per-user/${config.home.username}/bin/zen-beta \
      --name ${name} --class ${name} \
      --no-remote \
      --profile "$profile_dir" \
      --new-window ${url} "$@"
  '';
  notion = webApp "notion" "https://www.notion.so/";
  calendar = webApp "notion-calendar" "https://calendar.notion.so/";

  # Papirus ships a "notion" icon but none for Calendar. Install it into
  # hicolor so the launcher resolves it by name through the icon theme.
  calendarIcon = pkgs.runCommand "notion-calendar-icon" { } ''
    install -Dm644 ${pkgs.fetchurl {
      name = "notion-calendar.svg";
      url = "https://calendar.notion.so/notion-calendar-favicon.svg";
      hash = "sha256-jn2OKvBUkSf9FoUHZm44SvWN7uhhNS6Ns2llTJ5dcDA=";
    }} $out/share/icons/hicolor/scalable/apps/notion-calendar.svg
  '';
in
# Notion no longer serves Russia, so it comes with the other VPN apps.
lib.mkIf settings.vpnApps {
  home.packages = [ notion calendar calendarIcon ];

  xdg.desktopEntries.notion = {
    name = "Notion";
    comment = "Notion workspace";
    exec = "${notion}/bin/notion %U";
    icon = "notion";
    terminal = false;
    categories = [ "Office" ];
    settings.StartupWMClass = "notion";
  };
  xdg.desktopEntries.notion-calendar = {
    name = "Notion Calendar";
    comment = "Notion Calendar";
    exec = "${calendar}/bin/notion-calendar %U";
    icon = "notion-calendar";
    terminal = false;
    categories = [ "Office" "Calendar" ];
    settings.StartupWMClass = "notion-calendar";
  };
}
