{ config, pkgs, ... }:

{
  programs.gnome-terminal.enable = true;

  dconf.settings = {
    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
      theme-variant = "dark";
    };
    
    "org/gnome/terminal/legacy/profiles:" = {
      default = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
      list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" ];
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      visible-name = "Default";
      use-system-font = true;
      use-theme-colors = true;
      cursor-shape = "block";
      scrollback-lines = 10000;
      scrollbar-policy = "never";
    };
  };
}
