{ pkgs }:

let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation {
  pname = "chatgpt-desktop";
  version = "26.917.71314";

  src = pkgs.requireFile {
    name = "chatgpt_amd64.deb";
    sha256 = lib.removeSuffix "\n" (builtins.readFile ./source.sha256);
    message = ''
      Add the official ChatGPT installer to the Nix store:
      nix-store --add-fixed sha256 ~/Downloads/chatgpt_amd64.deb
    '';
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

    xorg.libX11
    xorg.libxcb
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
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
