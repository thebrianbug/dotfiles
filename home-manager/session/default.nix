{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    # Wayland-specific
    MOZ_ENABLE_WAYLAND = "1";  # Enable Wayland support in Firefox
    QT_QPA_PLATFORM = "wayland;xcb";  # Prefer Wayland but fallback to X11
    QT_STYLE_OVERRIDE = "Adwaita-Dark";  # Keep dark theme
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";  # Enable automatic scaling
    SDL_VIDEODRIVER = "wayland,x11";  # Prefer Wayland but fallback to X11
    XDG_SESSION_TYPE = "wayland";  # Indicate Wayland session
    XDG_CURRENT_DESKTOP = "GNOME";  # Keep GNOME desktop identification
    # Electron Wayland support - more permissive
    # ELECTRON_OZONE_PLATFORM_HINT = "auto";  # Let Electron choose best platform
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";  # Force Wayland
  };
}
