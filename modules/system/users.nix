{
  users.users.configuser = {
    isNormalUser = true;
    description = "Example user";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" ];
  };
}
