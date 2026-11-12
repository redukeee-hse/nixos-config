{ pkgs }:

let
  inherit (pkgs) lib;
  # Pinned below 2.21: 2.21 dropped the v1 HTTP API (/api/services,
  # /api/traces search) that Grafana's Jaeger data source still uses.
  version = "2.23.0";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "jaeger";
  inherit version;

  # Jaeger is not in nixpkgs; the official release ships a static binary
  # with the UI embedded.
  src = pkgs.fetchurl {
    url = "https://github.com/jaegertracing/jaeger/releases/download/v${version}/jaeger-${version}-linux-amd64.tar.gz";
    hash = "sha256-S3vRUu0x0iBeTnO4c9KJxhzT+rrsyGRDBwFDRI1At1M=";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 jaeger "$out/bin/jaeger"
    runHook postInstall
  '';

  meta = {
    description = "Distributed tracing platform (all-in-one v2 binary)";
    homepage = "https://www.jaegertracing.io";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "jaeger";
  };
}
