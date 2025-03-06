{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable GNOME Terminal
  programs.gnome-terminal = {
    enable = true;
    settings = {
      "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        default = true;
        name = "Default";
        showMenubar = false;
        audibleBell = false;
        backgroundColor = "rgb(23, 20, 33)";
        foregroundColor = "rgb(208, 207, 204)";
        useThemeColors = false;
        useSystemFont = true;
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
