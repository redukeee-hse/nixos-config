# `update` and `rebuild` from any directory; they run the scripts in the
# configuration's clone (settings.configDir, ~/nixos-config by default).
{ pkgs, settings, ... }:

let
  run = name: script: pkgs.writeShellScriptBin name ''
    exec ${pkgs.bash}/bin/bash ${settings.configDir}/scripts/${script} "$@"
  '';
in
{
  environment.systemPackages = [
    pkgs.git
    (run "update" "update.sh")
    (run "rebuild" "rebuild.sh")
  ];
}
