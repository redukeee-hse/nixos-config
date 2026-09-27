# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../../modules/desktop/login-theme.nix
      ../../modules/services/happ.nix
      ./hardware-configuration.nix
      ./packages.nix
    ];

  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # A pre-NixOS dconf database used to occupy /etc/dconf as a real directory.
  # Preserve it once so setup-etc can install the declarative dconf symlink.
  system.activationScripts.migrateLegacyDconf = {
    deps = [ "specialfs" ];
    text = ''
      if [[ -d /etc/dconf && ! -L /etc/dconf ]]; then
        if [[ -e /etc/dconf.pre-nix || -L /etc/dconf.pre-nix ]]; then
          echo "Refusing to migrate /etc/dconf: /etc/dconf.pre-nix already exists" >&2
          exit 1
        fi
        mv -- /etc/dconf /etc/dconf.pre-nix
      fi
    '';
  };
  system.activationScripts.etc.deps = [ "migrateLegacyDconf" ];

  services.power-profiles-daemon.enable = true;

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "confighost"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  fonts.packages = with pkgs; [
     dejavu_fonts
     noto-fonts
     noto-fonts-color-emoji
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";



  # Standalone graphical login for Hyprland, without the GNOME desktop.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.defaultSession = "hyprland";

  programs.nm-applet.enable = true;
  environment.localBinInPath = true;

  services.desktopManager.gnome.enable = false;

  services.nginx.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 22 ];  # SSH and HTTP/HTTPS

  # Database (PostgreSQL by default)
  services.postgresql.enable = true;
  services.resolved.enable = true;
  
  programs.throne = {
    enable = true;
    tunMode = {
      enable = true;
      setuid = true;
    };
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";   
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Install flatpak
  services.flatpak.enable = true; 

 # Enable sound with pipewire.
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


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.configuser = {
    isNormalUser = true;
    description = "Example user";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # secrets
  
  # Claude Desktop downloads a generic Linux Claude Code binary.
  programs.nix-ld.enable = true;

  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;



#  programs.hyprland.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget


  virtualisation.docker.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
 

  programs.hyprland = {
  enable = true;
  xwayland.enable = true;        # X11 application compatibility
};



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
