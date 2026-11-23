# Latest releases of Go tools on top of the nixpkgs recipes, built with Go 1.27.
# To update: change version, reset hash and vendorHash (lib.fakeHash), build
# and copy the hashes from the error (scripts/update-apps.py does this).
{
  lib,
  fetchFromGitHub,
  buildGo127Module,
  golangci-lint,
  oapi-codegen,
  goose,
}:

let
  bump =
    pkg:
    { version, hash, vendorHash, owner, repo }:
    (pkg.override (
      args: lib.mapAttrs (_: _: buildGo127Module) (lib.filterAttrs (n: _: lib.hasPrefix "buildGo" n) args)
    )).overrideAttrs
      (_: {
        inherit version vendorHash;
        src = fetchFromGitHub {
          inherit owner repo hash;
          tag = "v${version}";
        };
      });
in
{
  golangci-lint = bump golangci-lint {
    version = "2.15.0";
    owner = "golangci";
    repo = "golangci-lint";
    hash = "sha256-m9PoJHescRuT9DiKsb6LL+lQlc7RKAWDiRyf8pNMffA=";
    vendorHash = "sha256-gWbhZc/BJwuiwyTMaR1ShEBI1lo0bGLCXsdj5n91baw=";
  };

  oapi-codegen = bump oapi-codegen {
    version = "2.9.0";
    owner = "oapi-codegen";
    repo = "oapi-codegen";
    hash = "sha256-lBfYZTr3YEwVsQO8YZ+z+5nmLlB9ehJWvUrrxUHM7AU=";
    vendorHash = "sha256-AgFmVUnSmstfe1l4leS+3Dt8eL3Lercj1+6MuWsjvqY=";
  };

  goose = bump goose {
    version = "3.30.1";
    owner = "pressly";
    repo = "goose";
    hash = "sha256-Od+U34GQj2JfNNVR8nn1bmEjT7viU+z92Ep5bAjqUno=";
    vendorHash = "sha256-XfNZMFB11phhvzseGYONq99zlTnKoectfJI25FGzB2g=";
  };
}
