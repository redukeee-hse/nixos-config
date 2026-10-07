{
  description = "NixOS configuration and local applications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Machine-specific files live in ./local, which Git ignores and
      # `update` never touches (see README). Git-ignored files are invisible
      # to a git+file flake, so build with `--flake path:.#example`
      # (scripts/rebuild.sh and `update` do this).
      local = name: ./local + "/${name}";
      hasLocal = name: builtins.pathExists (local name);
      requireLocal = name:
        if hasLocal name then local name
        else throw ''
          local/${name} not found.
          Run ./scripts/configure-local.sh once, then build with `rebuild`
          (./scripts/rebuild.sh) or `nixos-rebuild --flake path:.#example`.
          A plain `--flake .#example` cannot see the git-ignored local/ folder;
          do not `git add` it.
        '';
      optionalLocal = name: nixpkgs.lib.optional (hasLocal name) (local name);
      settings = import ./lib/settings.nix (import (requireLocal "settings.nix"));
    in {
      packages.${system} = import ./packages { inherit pkgs; };

      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit settings; };
        modules = [
          ./hosts/example
          (requireLocal "hardware-configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit zen-browser settings; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${settings.username} = {
              imports = [ ./home/example ] ++ optionalLocal "home.nix";
            };
          }
        ] ++ optionalLocal "configuration.nix";
      };
    };
}
