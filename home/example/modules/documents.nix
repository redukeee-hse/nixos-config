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

  # OnlyOffice: the interface theme follows the light/dark mode. Its own
  # "Same as system" stays light here, so theme-mode.sh writes theme-light or
  # theme-dark on every switch; this sets it for the current mode after a
  # rebuild. The app rewrites the file itself, so only the one key is set.
  home.activation.onlyofficeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="$HOME/.config/onlyoffice/DesktopEditors.conf"
    mode=$(cat "$HOME/.config/current/theme-mode" 2>/dev/null)
    [[ "$mode" == light ]] || mode=dark
    run mkdir -p "$(dirname "$conf")"
    [[ -s "$conf" ]] || printf '[General]\n' > "$conf"
    if grep -q '^uitheme=' "$conf"; then
      run sed -i "s/^uitheme=.*/uitheme=theme-$mode/" "$conf"
    else
      run sed -i "/^\[General\]$/a uitheme=theme-$mode" "$conf"
    fi
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
