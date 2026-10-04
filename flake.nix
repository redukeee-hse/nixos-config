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
    in {
      packages.${system} = import ./packages { inherit pkgs; };

      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/example
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit zen-browser; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.configuser = import ./home/example;
          }
        ];
      };
    };
}
