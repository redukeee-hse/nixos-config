{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cmake
    gcc
    git
    gnumake
    go
    python312
  ];
}
