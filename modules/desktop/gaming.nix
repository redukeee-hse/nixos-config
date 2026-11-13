# Gaming bits from Ryoku: GameMode (CPU governor and priorities while a game
# runs), gamescope (a micro-compositor for games) and MangoHud overlays.
# Run a game as `gamemoderun mangohud %command%` (Steam launch options) or
# `gamescope -f -- <game>`.
{ pkgs, ... }:

{
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  environment.systemPackages = [ pkgs.mangohud ];
}
