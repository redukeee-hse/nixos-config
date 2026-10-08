# Viewers for files people send around: office documents, PDF and e-books,
# images, video and audio, archives. Defaults live in files/config/mimeapps.list.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    onlyoffice-desktopeditors # docx/xlsx/pptx and their ODF/legacy counterparts
    loupe # images
    mpv # video and audio
    file-roller # archives; the CLI tools below are its backends
    _7zz
    unrar
    unzip
    zip
  ];

  # PDF, DjVu, EPUB, XPS and comics. Colors follow the wallpaper: the include
  # is rewritten by wal-color-export.sh and picked up on the next launch.
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      font = "Inter 11";
      guioptions = "";
      recolor-keephue = true;
    };
    extraConfig = ''
      include ${config.xdg.configHome}/current/zathura-colors
    '';
  };

  home.activation.ensureZathuraColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/current"
    [[ -e "$HOME/.config/current/zathura-colors" ]] || run touch "$HOME/.config/current/zathura-colors"
  '';

  # Loupe and File Roller open files through D-Bus activation. The user bus
  # only rescans its service files on reload, so without this an app added by
  # a switch fails with "The name is not activatable" until the next login.
  home.activation.reloadUserDbus = lib.hm.dag.entryAfter [ "installPackages" ] ''
    bus="/run/user/$(id -u)/bus"
    if [[ -S "$bus" ]]; then
      run ${pkgs.systemd}/bin/busctl --address="unix:path=$bus" call \
        org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig || true
    fi
  '';
}
