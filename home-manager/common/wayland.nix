{ pkgs, ... }:

{
  # Wayland-specific session variables for all hosts
  home.sessionVariables = {
    # Enable Wayland support in applications
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland support
    QT_QPA_PLATFORM = "wayland;xcb"; # Prefer Wayland but fallback to X11
    QT_STYLE_OVERRIDE = "Adwaita-Dark"; # Keep dark theme
    QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # Enable automatic scaling
    SDL_VIDEODRIVER = "wayland,x11"; # Prefer Wayland but fallback to X11
    XDG_SESSION_TYPE = "wayland"; # Indicate Wayland session
    XDG_CURRENT_DESKTOP = "GNOME"; # Keep GNOME desktop identification
    ELECTRON_OZONE_PLATFORM_HINT = "wayland"; # Force Wayland for Electron apps
  };

  # Common Wayland utilities
  home.packages = with pkgs; [
    # Wayland core utilities
    wl-clipboard # Clipboard utilities for Wayland
    grim         # Screenshot utility for Wayland
    slurp        # Region selection for Wayland
    wf-recorder  # Screen recording for Wayland
    wlr-randr    # Screen configuration for wlroots compositors
    
    # Wayland compatibility
    qt6.qtwayland            # Qt Wayland support
    xdg-desktop-portal-wlr   # Desktop integration for wlroots
  ];
}
