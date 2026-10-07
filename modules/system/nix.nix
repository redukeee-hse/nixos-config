{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep the Nix store from growing forever: hard-link identical files and
  # drop generations older than two weeks once a week.
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  # Claude Desktop downloads a generic Linux Claude Code binary.
  programs.nix-ld.enable = true;
}
