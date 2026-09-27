{ pkgs }:

let
  inherit (pkgs) lib;
  version = "2.1.274";
  # SHA-256 from the official stable manifest:
  # https://downloads.claude.ai/claude-code-releases/2.1.274/manifest.json
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude";
    hash = "sha256-FeLQUUj4AbV3QDL6rYfmJOzRcumQMoi9pEi4kutY+gc=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = with pkgs; [ autoPatchelfHook makeBinaryWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp "$src" "$out/bin/claude"
    chmod 755 "$out/bin/claude"
    wrapProgram "$out/bin/claude" \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.alsa-lib ]}" \
      --prefix PATH : "${lib.makeBinPath (with pkgs; [ procps ripgrep bubblewrap socat ])}"
    runHook postInstall
  '';

  meta = {
    description = "Claude Code terminal coding assistant";
    homepage = "https://code.claude.com/docs/en/setup";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
