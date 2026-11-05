{ config, lib, pkgs, settings, ... }:

{
  xdg.configFile = {

    "waybar/config.jsonc".source = ../files/config/waybar/config.jsonc;
    # The palette is a link that theme-mode.sh points at colors-dark/light.css.
    "waybar/style.css".text = ''
      @import url("file://${config.xdg.configHome}/current/waybar-colors.css");
    '' + builtins.readFile ../files/config/waybar/style.css;
    "waybar/colors-dark.css".source = ../files/config/waybar/colors-dark.css;
    "waybar/colors-light.css".source = ../files/config/waybar/colors-light.css;

    # Settings panel (Super+I), power menu (Super+Esc) and wallpaper picker (Super+W).
    "quickshell" = {
      source = ../files/config/quickshell;
      recursive = true;
    };

    "eww/eww.yuck".source = ../files/config/eww/eww.yuck;
    # SCSS imports need an absolute path; @HOME@ is filled in here.
    "eww/eww.scss".text = builtins.replaceStrings [ "@HOME@" ] [ config.home.homeDirectory ]
      (builtins.readFile ../files/config/eww/eww.scss);


    "hypr/hyprland.conf".source = ../files/config/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ../files/config/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ../files/config/hypr/hyprlock.conf;
    "hyprland/nautilus.conf".source = ../files/config/hyprland/nautilus.conf;
    "hyprland/telegram.conf".source = ../files/config/hyprland/telegram.conf;
    # Keyboard layout from local/settings.nix, sourced by hyprland.conf.
    "hyprland/keyboard.conf".text = with settings.keyboard; ''
      input {
        kb_layout=${layout}
        kb_variant=${variant}
        kb_options=${options}
      }
    '';

    "swaync/config.json".source = ../files/config/swaync/config.json;
    # Keep the stock SwayNC look and only recolor it from the wallpaper palette.
    "swaync/style.css".text = ''
      @import url("file://${pkgs.swaynotificationcenter}/etc/xdg/swaync/style.css");
      @import url("file://${config.xdg.configHome}/current/swaync-colors.css");

      @define-color cc-bg @nc-panel;
      @define-color noti-bg @nc-bg;
      @define-color noti-border-color @nc-border;
      @define-color text-color @nc-fg;
      @define-color bg-selected @nc-accent;

      * { font-family: monospace; font-size: 10pt; }
      .notification-row .notification-background .notification { border-radius: 10px; }
      .control-center { border-radius: 10px; border: 1px solid @nc-border; }
    '';
    "mimeapps.list".source = ../files/config/mimeapps.list;

    "rofi/config.rasi".source = ../files/config/rofi/config.rasi;
  };

  # Leftovers of the manual Claude Desktop install and an old Zen handler.
  # They live in ~/.local/share/applications, shadow the Nix-provided entries
  # with the same id and point at paths that no longer exist.
  home.activation.removeStaleDesktopEntries = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    apps="${config.xdg.dataHome}/applications"
    run rm -f "$apps/com.anthropic.Claude.desktop" "$apps"/userapp-Zen-*.desktop
    if [ -L "$HOME/.local/bin/claude-desktop" ] && [ ! -e "$HOME/.local/bin/claude-desktop" ]; then
      run rm -f "$HOME/.local/bin/claude-desktop"
    fi
  '';
}
