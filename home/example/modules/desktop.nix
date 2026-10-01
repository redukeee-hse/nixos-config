{ config, pkgs, ... }:

{
  xdg.configFile = {
    "networkmanager-dmenu/config.ini".source = ../files/config/networkmanager-dmenu/config.ini;
    "rofi/wifi.rasi".source = ../files/config/rofi/wifi.rasi;

    "waybar/min.jsonc".source = ../files/config/waybar/min.jsonc;
    "waybar/max.jsonc".source = ../files/config/waybar/max.jsonc;
    "waybar/min.css".source = ../files/config/waybar/min.css;
    "waybar/max.css".source = ../files/config/waybar/max.css;

    "eww/eww.yuck".source = ../files/config/eww/eww.yuck;
    "eww/eww.scss".source = ../files/config/eww/eww.scss;

    "cava/waybar-left".source = ../files/config/cava/waybar-left;
    "cava/waybar-right".source = ../files/config/cava/waybar-right;

    "hypr/hyprland.conf".source = ../files/config/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ../files/config/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ../files/config/hypr/hyprlock.conf;
    "hyprland/firefox.conf".source = ../files/config/hyprland/firefox.conf;
    "hyprland/nautilus.conf".source = ../files/config/hyprland/nautilus.conf;
    "hyprland/telegram.conf".source = ../files/config/hyprland/telegram.conf;

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

    "walker/config.toml".source = ../files/config/walker/config.toml;
    "walker/themes/transparent-apps.css".source = ../files/config/walker/themes/transparent-apps.css;
    "walker/themes/transparent-apps.toml".source = ../files/config/walker/themes/transparent-apps.toml;
    "walker/themes/transparent-power.css".source = ../files/config/walker/themes/transparent-power.css;
    "walker/themes/transparent-power.toml".source = ../files/config/walker/themes/transparent-power.toml;
    "walker/themes/transparent-system.css".source = ../files/config/walker/themes/transparent-system.css;
    "walker/themes/transparent-system.toml".source = ../files/config/walker/themes/transparent-system.toml;
  };
}
