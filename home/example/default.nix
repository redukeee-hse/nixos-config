{ settings, ... }:

{
  imports = [
    ./modules/appearance.nix
    ./modules/browser.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/documents.nix
    ./modules/notion.nix
    ./modules/packages.nix
    ./modules/scripts.nix
    ./modules/shell.nix
    ./modules/xdg.nix
  ];

  home.username = settings.username;
  home.homeDirectory = "/home/${settings.username}";
  home.stateVersion = settings.homeStateVersion;

  programs.home-manager.enable = true;
}
