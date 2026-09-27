{ lib, ... }:

{
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "Noto Sans 11";
    document-font-name = "Noto Sans 11";
    monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
  };
  xdg.configFile = {
    "gtk-3.0" = {
      source = ../files/config/gtk-3.0;
      recursive = true;
    };
    "gtk-4.0" = {
      source = ../files/config/gtk-4.0;
      recursive = true;
    };
    "current/wal-colors-template.css".source = ../files/config/current/wal-colors-template.css;
  };

  # Qt settings are mutable; only align the font entries and preserve themes.
  home.activation.alignQtFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for target in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
      if [[ -f "$target" && ! -L "$target" ]]; then
        run sed -i \
          -e 's/^general=.*/general="Noto Sans,11,-1,5,50,0,0,0,0,0,Regular"/' \
          -e 's/^fixed=.*/fixed="JetBrainsMono Nerd Font Mono,11,-1,5,50,0,0,0,0,0,Regular"/' \
          "$target"
      fi
    done
  '';

  # Pywal rewrites this file after every wallpaper change. Home Manager only
  # seeds a palette on a fresh system and deliberately leaves it mutable.
  home.activation.ensureWifiColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/mako"
    if [[ ! -e "$HOME/.config/mako/colors" ]]; then
      run touch "$HOME/.config/mako/colors"
    fi
    target="$HOME/.config/rofi/wifi-colors.rasi"
    if [[ ! -e "$target" ]]; then
      run mkdir -p "$(dirname "$target")"
      run cp ${../files/config/rofi/wifi-colors-fallback.rasi} "$target"
      run chmod u+w "$target"
    fi
  '';

  # Walker consumes this generated palette. The export script updates it when
  # the wallpaper changes; activation only provides a fallback and migration.
  home.activation.ensureDynamicThemeColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/current"
    if [[ ! -e "$HOME/.config/current/hypr-colors.conf" ]]; then
      run touch "$HOME/.config/current/hypr-colors.conf"
    fi
    target="$HOME/.config/current/wal-colors.css"
    if [[ ! -e "$target" ]]; then
      run mkdir -p "$(dirname "$target")"
      run cp ${../files/config/current/wal-colors-fallback.css} "$target"
      run chmod u+w "$target"
    fi
    run sed -i '/^@define-color border #999999;$/d' "$target"
  '';
}
