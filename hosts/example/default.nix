# Example host. Everything that is not specific to one machine lives in
# ../../modules; your names, time zone, stateVersion and hardware come from
# the git-ignored ../../local folder (see local.example/).
{ settings, ... }:

{
  imports = [
    ../../modules/system
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/services
  ];

  networking.hostName = settings.hostname;

  # The NixOS release from which the default settings for stateful data,
  # like file locations and database versions, were taken. It comes from
  # local/settings.nix and must stay at the release of YOUR first install.
  system.stateVersion = settings.stateVersion;
}
