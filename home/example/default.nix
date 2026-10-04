{
  imports = [
    ./modules/appearance.nix
    ./modules/browser.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/notion.nix
    ./modules/packages.nix
    ./modules/scripts.nix
    ./modules/shell.nix
    ./modules/xdg.nix
  ];

  home.username = "configuser";
  home.homeDirectory = "/home/configuser";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
