# Current Postman on top of the nixpkgs recipe, which lags behind.
# Latest version: curl -s 'https://dl.pstmn.io/api/version/latest?platform=linux64'
# Hash: nix store prefetch-file https://dl.pstmn.io/download/version/<version>/linux64
{ path, callPackage, fetchurl, postman }:

let
  version = "12.36.3";
in
(callPackage "${path}/pkgs/by-name/po/postman/linux.nix" {
  pname = "postman";
  inherit version;
  src = fetchurl {
    name = "postman-${version}.tar.gz";
    url = "https://dl.pstmn.io/download/version/${version}/linux64";
    hash = "sha256-g9fXe9FGFFnKfTpYKd8PWhGNCdFpRKqXPk0mRryuCnw=";
  };
  passthru = { };
  inherit (postman) meta;
}).overrideAttrs (old: {
  # Since 12.x the archive bundles postman-cli: the shell script bin/postman
  # and language-server.source.ts, which the recipe tries to patchelf (globs
  # "-name postman" and "*.so*"). Narrow the globs to real ELF files.
  postFixup =
    let
      fixed = builtins.replaceStrings
        [ "-name postman -o" "-name \\*.so\\*" ]
        [ "-path '*/share/postman/postman' -o" "-name \\*.so -o -name \\*.so.\\*" ]
        old.postFixup;
    in
    assert fixed != old.postFixup;
    fixed;
})
