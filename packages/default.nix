# Local package catalogue. Add new recipes here.
{ pkgs }:
{
  claude-desktop = pkgs.callPackage ./claude-desktop { };
  claude-code = pkgs.callPackage ./claude-code { };
  chatgpt = pkgs.callPackage ./chatgpt { };
  happ = pkgs.callPackage ./happ { forceXwayland = true; };
}
