{ config, pkgs, ... }:

{
  xsession = {
    enable = true;
    windowManager.command = "gnome-session";
  };

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "Alacritty.desktop"
        "obsidian.desktop"
        "vesktop.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "codium.desktop"
      ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    wl-clipboard
    alacritty

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];
}
