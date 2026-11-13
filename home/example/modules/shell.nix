{ lib, ... }:

{
  home.file.".bashrc".source = ../files/home/bashrc;

  xdg.configFile = {
    # Kitty is the terminal now; the Alacritty config stays for a quick way back.
    "alacritty/alacritty.toml".source = ../files/config/alacritty/alacritty.toml;
    "kitty/kitty.conf".source = ../files/config/kitty/kitty.conf;
    "fish/config.fish".source = ../files/config/fish/config.fish;
    "fastfetch/config.jsonc".source = ../files/config/fastfetch/config.jsonc;
    "fastfetch/nixos.png".source = ../files/config/fastfetch/nixos.png;
    "starship.toml".source = ../files/config/starship.toml;
  };

  # Kitty runs one process for all windows (term.sh: kitty -1), so a new
  # config only reaches it after a reload; SIGUSR1 makes kitty reread it.
  home.activation.reloadKitty = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run pkill -USR1 -x kitty || true
  '';
}
