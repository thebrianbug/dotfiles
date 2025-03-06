{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable GNOME Terminal
  programs.gnome-terminal = {
    enable = true;
    profile = {
      "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        default = true;
        visibleName = "Default";
        showMenubar = false;
        audibleBell = false;
        colors = {
          backgroundColor = "rgb(23, 20, 33)";
          foregroundColor = "rgb(208, 207, 204)";
          useThemeColors = false;
        };
        font = {
          useSystemFont = true;
        };
      };
    };
  };

  # GNOME Terminal keyboard shortcut
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Launch Terminal";
    };
  };
}
