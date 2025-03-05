{ config, pkgs, lib, ... }:

{
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
      edge-tiling = true;
      workspaces-only-on-primary = true;
      remember-window-size = true;
    };

    # Add window state preservation settings
    "org/gnome/shell/overrides" = {
      edge-tiling = true;
      attach-modal-dialogs = true;
    };
    
    # Add specific window management rules
    "org/gnome/desktop/wm/keybindings" = {
      toggle-fullscreen = ["<Super>f"];
    };
    
    # Window state preservation
    "org/gnome/mutter/wayland" = {
      restore-monitor-config = true;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.gnome.Terminal.desktop"
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
      auto-maximize = true;  # Automatically maximize windows like Obsidian
    };

    # Autostart applications
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "firefox.desktop:1"  # Start Firefox on workspace 1
        "org.keepassxc.KeePassXC.desktop:1"  # Start KeePassXC on workspace 1
        "obsidian.desktop:2"  # Start Obsidian on workspace 2
        "vesktop.desktop:3"  # Start Vesktop (Discord) on workspace 3
      ];
    };

    # Desktop icons settings
    "org/gnome/shell/extensions/ding" = {
      show-home = false;  # Hide home folder on desktop
      show-trash = true;  # Show trash icon on desktop
    };

    # Autostart settings
    "org/gnome/shell/extensions/dash-to-dock" = {
      click-action = "minimize";
      dock-fixed = true;
      extend-height = true;
      dock-position = "LEFT";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Launch Terminal";
    };

    # Additional autostart applications
    "org/gnome/shell/extensions/autostart" = {
      autostart-apps = [
        "firefox.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "obsidian.desktop"
        "vesktop.desktop"
        "org.gnome.Terminal.desktop"
      ];
    };
  };

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    gnome-shell-extensions  # Required for autostart functionality
    adwaita-icon-theme  # Ensure proper GNOME theming
    nerd-fonts.jetbrains-mono
    libcanberra-gtk3    # Sound support for GTK apps

    # Wayland utilities
    wl-clipboard  # Clipboard management
    grim         # Screenshot utility
    slurp        # Screen area selection
    wf-recorder  # Screen recording
    wlr-randr    # Screen management
    qt6.qtwayland    # Qt6 Wayland support
    xdg-desktop-portal-wlr  # Screen sharing

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";  # Use Wayland for Qt applications
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";  # Enable HiDPI scaling
    # Add specific Electron flags for Vesktop
    ELECTRON_ENABLE_STACK_DUMPING = "1";    # Better error reporting
  };
}
