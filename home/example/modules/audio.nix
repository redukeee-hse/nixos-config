{ lib, pkgs, settings, ... }:
# Huawei MateBook speakers (huaweiAudio in local/settings.nix).
lib.mkIf settings.huaweiAudio {
  # On this SN6140 laptop, PipeWire controls the Headphone DAC for speakers.
  # Keep the separate Speaker stage on and at 0 dB so the displayed volume does not
  # acquire an extra, untracked attenuation (previously -23 dB).
  systemd.user.services.huawei-speaker-gain = {
    Unit = {
      Description = "Keep Huawei speaker amplifier at unity gain";
      # The card only becomes usable for the user once sound.target is reached;
      # starting earlier fails with "Invalid card number".
      After = [ "wireplumber.service" "sound.target" ];
      Wants = [ "wireplumber.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set Speaker 100% unmute";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" "sound.target" ];
  };
}
