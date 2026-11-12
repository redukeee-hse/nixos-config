{ pkgs, ... }:
let
  # Rotating dark planet; the SDDM login screen plays the same frames, so
  # boot and login look like one continuous screen.
  planetTheme = pkgs.adi1090x-plymouth-themes.override {
    selected_themes = [ "dark_planet" ];
  };
in
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    devices = [ "nodev" ];
    efiSupport = true;
    # Finds other systems (e.g. Windows) for the boot menu. If NixOS is the
    # only system, set this to false and add `timeoutStyle = "hidden";` to
    # skip the menu (hold Esc to show it).
    useOSProber = true;
    # No gray NixOS wallpaper while GRUB loads the kernel: plain black, so
    # the screen goes straight from the firmware logo to the boot splash.
    splashImage = null;
    backgroundColor = "#000000";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Boot splash: the dark planet on black instead of status lines.
  # Tip: add your GPU driver to boot.initrd.kernelModules in
  # local/configuration.nix ("i915" for Intel, "amdgpu" for AMD) so the splash
  # appears at native resolution right away.
  boot.plymouth = {
    enable = true;
    theme = "dark_planet";
    themePackages = [ planetTheme ];
    # Fixed 2x scale: the frames are 467x350, and the login screen draws
    # them at the same 2x so the planet doesn't jump between the two.
    extraConfig = "DeviceScale=2";
  };

  # Quiet boot: no kernel/systemd status lines under the splash.
  # Errors still get through: kernel messages at KERN_CRIT and above, and with
  # `quiet` systemd only prints a unit status when it fails or hangs.
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
  ];

  # Compressed swap in RAM: under memory pressure pages go to zram first,
  # which is much faster than a disk swap partition.
  zramSwap.enable = true;
}
