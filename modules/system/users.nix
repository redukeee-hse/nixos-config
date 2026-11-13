{ settings, ... }:

{
  users.users.${settings.username} = {
    isNormalUser = true;
    description = settings.fullName;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };
  # fish is the interactive shell inside kitty (completions and vendor
  # functions come from here); the login shell stays bash for scripts.
  programs.fish.enable = true;
}
