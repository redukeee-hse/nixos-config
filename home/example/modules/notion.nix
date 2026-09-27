{ pkgs, ... }:

let
  # Zen is already installed in this Home Manager profile. Dedicated profiles
  # give the two official web apps separate, persistent desktop windows.
  webApp = name: url: pkgs.writeShellScriptBin name ''
    profile_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/${name}-profile"
    mkdir -p "$profile_dir"
    exec /etc/profiles/per-user/configuser/bin/zen-beta \
      --no-remote \
      --profile "$profile_dir" \
      --new-window ${url} "$@"
  '';
  notion = webApp "notion" "https://www.notion.so/";
  calendar = webApp "notion-calendar" "https://calendar.notion.so/";
in
{
  home.packages = [ notion calendar ];

  xdg.desktopEntries.notion = {
    name = "Notion";
    comment = "Notion workspace";
    exec = "${notion}/bin/notion";
    icon = "notion";
    terminal = false;
    categories = [ "Office" ];
  };
  xdg.desktopEntries.notion-calendar = {
    name = "Notion Calendar";
    comment = "Notion Calendar";
    exec = "${calendar}/bin/notion-calendar";
    icon = "x-office-calendar";
    terminal = false;
    categories = [ "Office" "Calendar" ];
  };
}
