{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    git
    go
    python312
  ];
}
