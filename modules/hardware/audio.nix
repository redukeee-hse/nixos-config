{ lib, pkgs, ... }:

{
  hardware.alsa.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = lib.mkForce true;
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
