{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable GNOME Terminal
  programs.gnome-terminal = {
    enable = true;
  };
}
