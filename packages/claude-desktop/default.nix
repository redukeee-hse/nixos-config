{ pkgs }:

let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation {
  pname = "claude-desktop";
  version = "2.7032.0";

  # Official Anthropic apt repository, verified against its signed Packages index.
  src = pkgs.fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_2.7032.0_amd64.deb";
    hash = "sha256-Hn9FBLylsvay08QSPRRdcnZH538u4tBGhQcR5h59exE=";
  };

  nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libcap_ng
    libseccomp
    libgbm
    libGL
    libnotify
    libsecret
    libuuid
    libxkbcommon
    nss
    nspr
    pango
    systemd
    vulkan-loader
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
  ];

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir extracted
    dpkg-deb --fsys-tarfile "$src" | tar --no-same-owner --no-same-permissions -xf - -C extracted
    mkdir -p "$out/bin" "$out/lib" "$out/share"
    cp -a extracted/usr/lib/claude-desktop "$out/lib/"
    cp -a extracted/usr/share/applications extracted/usr/share/icons "$out/share/"
    chmod u-s "$out/lib/claude-desktop/chrome-sandbox"
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils pkgs.glib ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libsecret ]}" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--password-store=gnome-libsecret"
    substituteInPlace "$out/share/applications/com.anthropic.Claude.desktop" \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"
    runHook postInstall
  '';

  meta = {
    description = "Official Claude Desktop app from Anthropic";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
