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
    # libadwaita (GTK4) apps such as Nautilus ignore gtk-theme-name.
    color-scheme = "prefer-dark";
    # On Wayland GTK4 takes the icon theme from here, not settings.ini.
    icon-theme = "Papirus-Dark";
    font-name = "Noto Sans 11";
    document-font-name = "Noto Sans 11";
    monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
  };
  # Client-side decorations: a single close button on the right. Hyprland
  # tiles windows, so minimize/maximize buttons would do nothing.
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:close";
  xdg.configFile = {
    "gtk-3.0" = {
      source = ../files/config/gtk-3.0;
      recursive = true;
    };
    "gtk-4.0" = {
      source = ../files/config/gtk-4.0;
      recursive = true;
    };
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

  # wal-color-export.sh rewrites these files after every wallpaper change.
  # Home Manager only seeds a palette on a fresh system and leaves them mutable.
  home.activation.ensureSwayncColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/current/swaync-colors.css"
    if [[ ! -e "$target" ]]; then
      run mkdir -p "$(dirname "$target")"
      run cp ${../files/config/current/swaync-colors-fallback.css} "$target"
      run chmod u+w "$target"
    fi
  '';

  # Rofi consumes this generated palette. The export script updates it when
  # the wallpaper changes; activation only provides a fallback and migration.
  home.activation.ensureDynamicThemeColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/current"
    if [[ ! -e "$HOME/.config/current/hypr-colors.conf" ]]; then
      run touch "$HOME/.config/current/hypr-colors.conf"
    fi
    target="$HOME/.config/current/rofi-colors.rasi"
    if [[ ! -e "$target" ]]; then
      run cp ${../files/config/current/rofi-colors-fallback.rasi} "$target"
      run chmod u+w "$target"
    fi
  '';
}
