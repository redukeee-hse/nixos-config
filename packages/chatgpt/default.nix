{ pkgs }:

let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation {
  pname = "chatgpt-desktop";
  version = "26.1106.51428";

  # The official link always serves the latest release. When OpenAI ships a
  # new one, the build fails with a hash mismatch until version and
  # source.sha256 are updated (scripts/update-apps.py chatgpt).
  src = pkgs.fetchurl {
    name = "chatgpt_amd64.deb";
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = lib.removeSuffix "\n" (builtins.readFile ./source.sha256);
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    gtk3
    glib
    gdk-pixbuf
    cairo
    pango
    at-spi2-core
    nss
    nspr
    dbus
    cups
    alsa-lib
    libnotify
    libdrm
    libgbm
    libGL
    libxkbcommon
    expat
    openssl
    tpm2-tss
    libusb1
    systemd
    libsecret
    libcanberra
    vulkan-loader

    zlib
    zstd
    bzip2
    xz
    libffi
    sqlite
    libxcrypt
    util-linux
    ncurses
    readline

    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcursor
    libxi
    libxrender
    libxtst
    libxscrnsaver
  ];

  runtimeDependencies = with pkgs; [
    libGL
    libgbm
    vulkan-loader
    systemd
    libsecret
    libnotify
  ];

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapQtApps = true;

  # Unused musl variants of bundled Node.js modules.
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
  ];

  preFixup = ''
    addAutoPatchelfSearchPath "${lib.getLib pkgs.qt5.qtbase}/lib"
    addAutoPatchelfSearchPath "${lib.getLib pkgs.qt6.qtbase}/lib"
  '';

  installPhase = ''
    runHook preInstall

    dpkg-deb -x "$src" extracted

    mkdir -p "$out/lib" "$out/bin" "$out/share"
    cp -a extracted/usr/lib/chatgpt "$out/lib/"
    ${pkgs.python3}/bin/python3 ${./patches/fix-node-report.py} \
      "$out/lib/chatgpt/ChatGPT"

    for dir in applications icons pixmaps; do
      if [ -d "extracted/usr/share/$dir" ]; then
        cp -a "extracted/usr/share/$dir" "$out/share/"
      fi
    done

    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      --prefix PATH : "${lib.makeBinPath [
        pkgs.coreutils
        pkgs.xdg-utils
        pkgs.glib
        pkgs.bash
      ]}" \
      --add-flags "--ozone-platform=x11"

    substituteInPlace "$out/share/applications/chatgpt.desktop" \
      --replace-fail "Exec=chatgpt" "Exec=$out/bin/chatgpt"

    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop application";
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
    license = lib.licenses.unfree;
  };
}
