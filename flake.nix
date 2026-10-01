{
  description = "NixOS configuration and local applications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Walker 0.13 (legacy GTK4 themes); 26.05 ships the incompatible 2.x rewrite
    nixpkgs-walker.url = "github:nixos/nixpkgs/6c5e707c6b5339359a9a9e215c5e66d6d802fd7a";

    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-walker, home-manager, zen-browser }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.${system} = import ./packages { inherit pkgs; };

      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/example
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit zen-browser nixpkgs-walker; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.configuser = import ./home/example;
          }
        ];
      };
    };
}
