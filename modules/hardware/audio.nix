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
    jack.enable = true;
  };

  # Diagnostic tools: amixer, pactl, wpctl.
  environment.systemPackages = with pkgs; [
    alsa-utils
    pipewire
    pulseaudioFull
    wireplumber
  ];
}
