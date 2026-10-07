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
      "custom/bin/close-active.sh" = script "close-active.sh";
      "custom/bin/cycle-moving-background.sh" = script "cycle-moving-background.sh";
      "custom/bin/gpu-usage.sh" = script "gpu-usage.sh";
      "custom/bin/language-indicator.sh" = script "language-indicator.sh";
      "custom/bin/mic-osd.sh" = script "mic-osd.sh";
      "custom/bin/set-wallpaper.sh" = script "set-wallpaper.sh";
      "custom/bin/sync-sddm-theme.sh" = script "sync-sddm-theme.sh";
      "custom/bin/term.sh" = script "term.sh";
      "custom/bin/tray-toggle.sh" = script "tray-toggle.sh";
      "custom/bin/volume-osd.sh" = script "volume-osd.sh";
      "custom/bin/waybar-run.sh" = script "waybar-run.sh";
      "custom/bin/vscode-current-dir.sh" = script "vscode-current-dir.sh";
      "custom/bin/vscode-wal-colors.py" = script "vscode-wal-colors.py";
      "custom/bin/wal-color-export.sh" = script "wal-color-export.sh";
      "custom/bin/power-profile.sh" = script "power-profile.sh";
      "custom/bin/session-start.sh" = script "session-start.sh";
    };
}
