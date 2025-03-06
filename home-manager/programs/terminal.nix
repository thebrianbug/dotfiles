{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable GNOME Terminal
  programs.gnome-terminal = {
    enable = true;
  };

  # GNOME Terminal configuration
  dconf.settings = {
    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
      theme-variant = "dark";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      audible-bell = false;
      background-color = "rgb(23, 20, 33)";
      foreground-color = "rgb(208, 207, 204)";
      use-system-font = true;
      use-theme-colors = false;
      visible-name = "Default";
      default-size-columns = 120;
      default-size-rows = 35;
    };

    # Terminal keyboard shortcut
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Launch Terminal";
    };
  };
}
