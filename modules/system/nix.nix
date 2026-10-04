{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # Claude Desktop downloads a generic Linux Claude Code binary.
  programs.nix-ld.enable = true;
}
