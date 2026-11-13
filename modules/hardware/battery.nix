# Battery care, after Ryoku's ryoku-power: a charge limit the user can switch
# from the Hub without sudo, and UPower for the battery readings and alerts.
{ pkgs, ... }:

{
  services.upower.enable = true;

  # Let the logged-in user set the charge limit (Hub > Power): the threshold
  # files become group-writable for "users". The value itself is reapplied at
  # login from ~/.config/current/charge-limit (battery-care user service).
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", \
      RUN+="${pkgs.coreutils}/bin/chgrp users /sys%p/charge_control_end_threshold /sys%p/charge_control_start_threshold", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/charge_control_end_threshold /sys%p/charge_control_start_threshold"
  '';
}
