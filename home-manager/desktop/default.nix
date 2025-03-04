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
      button-layout = ":minimize,maximize,close";  # Show window controls on the right without appmenu
      resize-with-right-button = true;
    };
  };

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    adwaita-icon-theme  # Ensure proper GNOME theming
    nerd-fonts.jetbrains-mono
    libcanberra-gtk3    # Sound support for GTK apps
    pkgtk               # Package kit GTK module

    # Wayland utilities
    wl-clipboard
    grim         # Screenshot utility
    slurp        # Screen area selection
    wf-recorder  # Screen recording
    waypipe      # Network transparency
    wlr-randr    # Screen management
    qt5.qtwayland    # Qt Wayland support
    qt6.qtwayland    # Qt6 Wayland support
    libsForQt5.qt5.qtwayland  # Additional Qt Wayland integration
    xdg-desktop-portal-wlr  # Screen sharing

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";  # Prefer Wayland, fallback to XCB
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";  # Let GNOME handle decorations
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";  # Enable HiDPI scaling
  };
}
