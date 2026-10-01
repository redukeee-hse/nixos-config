{
  xdg.dataFile =
    let
      script = name: {
        source = ../files/bin + "/${name}";
        executable = true;
      };
    in {
      "custom/bin/apply-palette.sh" = script "apply-palette.sh";
      "custom/bin/brightness-osd.sh" = script "brightness-osd.sh";
      "custom/bin/cava-json.sh" = script "cava-json.sh";
      "custom/bin/cycle-background.sh" = script "cycle-background.sh";
      "custom/bin/cycle-moving-background.sh" = script "cycle-moving-background.sh";
      "custom/bin/logo-printer.sh" = script "logo-printer.sh";
      "custom/bin/language-indicator.sh" = script "language-indicator.sh";
      "custom/bin/mic-osd.sh" = script "mic-osd.sh";
      "custom/bin/set-wallpaper.sh" = script "set-wallpaper.sh";
      "custom/bin/sync-sddm-theme.sh" = script "sync-sddm-theme.sh";
      "custom/bin/toggle-screenrecord.sh" = script "toggle-screenrecord.sh";
      "custom/bin/volume-osd.sh" = script "volume-osd.sh";
      "custom/bin/vscode-current-dir.sh" = script "vscode-current-dir.sh";
      "custom/bin/wal-color-export.sh" = script "wal-color-export.sh";
      "custom/bin/walker-menu.sh" = script "walker-menu.sh";
      "custom/bin/session-start.sh" = script "session-start.sh";
      "custom/bin/waybar-auto.sh" = script "waybar-auto.sh";
      "custom/bin/waybar-cava-snacks.sh" = script "waybar-cava-snacks.sh";
    };
}
