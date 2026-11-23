{ lib, pkgs, ... }:

{
  # No hardware.alsa.enable: that module is for ALSA without a sound server.
  # Its /etc/asound.conf points the ALSA "default" device at the raw card
  # (the empty headset-jack input), so ALSA apps such as arecord and voice
  # dictation recorded silence instead of going through PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Don't remember which output an app was moved to: audio-by-screen.sh
    # moves streams to the monitor's speakers, and a remembered target kept
    # the browser on them even with Bluetooth headphones as the default.
    wireplumber.extraConfig."10-no-restore-target" = {
      "wireplumber.settings"."node.stream.restore-target" = false;
    };
  };

  # Diagnostic tools: amixer, wpctl.
  environment.systemPackages = with pkgs; [
    alsa-utils
    pipewire
    wireplumber
  ];
}
