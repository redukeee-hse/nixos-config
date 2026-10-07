{ pkgs, ... }:
let
  plymouthTheme = pkgs.runCommand "nixos-logo-plymouth-theme" { } ''
    dir="$out/share/plymouth/themes/nixos-logo"
    mkdir -p "$dir"
    cp ${./plymouth-theme/nixos.script} "$dir/nixos-logo.script"
    cp ${pkgs.nixos-icons}/share/icons/hicolor/512x512/apps/nix-snowflake-white.png "$dir/logo.png"
    cat > "$dir/nixos-logo.plymouth" <<EOF
    [Plymouth Theme]
    Name=nixos-logo
    Description=NixOS logo on black
    ModuleName=script

    [script]
    ImageDir=$dir
    ScriptFile=$dir/nixos-logo.script
    EOF
  '';
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

  # Boot splash: the NixOS logo on black instead of status lines.
  # Tip: add your GPU driver to boot.initrd.kernelModules in
  # local/configuration.nix ("i915" for Intel, "amdgpu" for AMD) so the splash
  # appears at native resolution right away.
  boot.plymouth = {
    enable = true;
    theme = "nixos-logo";
    themePackages = [ plymouthTheme ];
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
