{ lib, pkgs, ... }:

{
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Inter" ];
      serif = [ "Inter" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  # color-scheme, gtk-theme and icon-theme follow the light/dark mode and are
  # written by theme-mode.sh (Super+Shift+Space), so they are not set here.
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "Inter 11";
    document-font-name = "Inter 11";
    monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
    # One cursor everywhere: the same theme and size as Hyprland and SDDM
    # (sddm.nix), gold to match the planet. libadwaita apps read these.
    cursor-theme = "Bibata-Modern-Amber";
    cursor-size = 16;
  };
  # XWayland and other plain X cursor users fall back to the "default" theme.
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Bibata-Modern-Amber
  '';
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
          -e 's/^general=.*/general="Inter,11,-1,5,50,0,0,0,0,0,Regular"/' \
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
    # Palettes written before the rosa-style cards lack the card and critical
    # colours; add them from the current pywal palette until the next export.
    if [[ ! -v DRY_RUN ]] && ! grep -q 'nc-card' "$target"; then
      wal="$HOME/.cache/wal/colors.json"
      card=$(${pkgs.jq}/bin/jq -r '.special.background // empty' "$wal" 2>/dev/null || true)
      bad=$(${pkgs.jq}/bin/jq -r '.colors.color1 // empty' "$wal" 2>/dev/null || true)
      printf '@define-color nc-card %s;\n@define-color nc-bad %s;\n' \
        "''${card:-#010101}" "''${bad:-#ff5555}" >> "$target"
    fi
  '';

  # Rofi consumes this generated palette. The export script updates it when
  # the wallpaper changes; activation only provides a fallback and migration.
  home.activation.ensureDynamicThemeColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/current"
    if [[ ! -e "$HOME/.config/current/hypr-colors.conf" ]]; then
      run touch "$HOME/.config/current/hypr-colors.conf"
    fi
    # Light/dark mode state, see theme-mode.sh. Without a theme-mode file the
    # mode is dark, with the wallpaper picker on ~/Wallpapers/Pictures/Dark.
    run mkdir -p "$HOME/Wallpapers/Pictures/Light" "$HOME/Wallpapers/Pictures/Dark"
    mode=$(cat "$HOME/.config/current/theme-mode" 2>/dev/null || true)
    [[ "$mode" == light ]] || mode=dark
    if [[ ! -e "$HOME/.config/current/waybar-colors.css" ]]; then
      run ln -nsf "$HOME/.config/waybar/colors-$mode.css" "$HOME/.config/current/waybar-colors.css"
    fi
    if [[ ! -e "$HOME/.config/current/wallpaper-dir" ]]; then
      run ln -nsf "$HOME/Wallpapers/Pictures/''${mode^}" "$HOME/.config/current/wallpaper-dir"
    fi
    target="$HOME/.config/current/rofi-colors.rasi"
    if [[ ! -e "$target" ]]; then
      run cp ${../files/config/current/rofi-colors-fallback.rasi} "$target"
      run chmod u+w "$target"
    fi
  '';
}
