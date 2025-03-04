{ config, pkgs, ... }:

{
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
      edge-tiling = true;
    };
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
      enable-hot-corners = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";  # Ensure window controls are visible
      resize-with-right-button = true;
    };
  };

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    adwaita-icon-theme  # Ensure proper GNOME theming
    nerd-fonts.jetbrains-mono

    # Wayland utilities
    wl-clipboard
    grim         # Screenshot utility
    slurp        # Screen area selection
    wf-recorder  # Screen recording
    waypipe      # Network transparency
    wlr-randr    # Screen management
    qt5.qtwayland  # Qt Wayland support
    xdg-desktop-portal-wlr  # Screen sharing

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];
}
