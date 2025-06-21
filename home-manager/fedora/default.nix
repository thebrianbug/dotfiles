{ config, pkgs, ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # Enable genericLinux support for Fedora
  targets.genericLinux.enable = true;

  # Fedora-specific packages
  home.packages = with pkgs; [
    # Wayland utilities (Fedora uses Wayland by default)
    wl-clipboard
    clipman
    grim
    slurp
    wf-recorder
    wlr-randr
    qt6.qtwayland
    xdg-desktop-portal-wlr
    
    # Applications more likely to be used on a full desktop environment
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];
  
  # Fedora-specific session variables
  home.sessionVariables = {
    # Wayland-specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_STYLE_OVERRIDE = "Adwaita-Dark";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    SDL_VIDEODRIVER = "wayland,x11";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
}
