{ config, pkgs, settings, ... }:

{
  xdg.configFile = {

    "waybar/config.jsonc".source = ../files/config/waybar/config.jsonc;
    "waybar/style.css".source = ../files/config/waybar/style.css;

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
}
