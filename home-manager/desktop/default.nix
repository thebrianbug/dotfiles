{ config, pkgs, lib, ... }:

{
  dconf.settings = {
    # Mutter window and focus settings
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
      edge-tiling = true;
      workspaces-only-on-primary = true;
      remember-window-size = true;
      focus-change-on-pointer-rest = true;
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

    # Application specific window rules
    "org/gnome/shell/extensions/auto-move-windows" = {
      focus-new-windows = true;  # Ensure new windows get focus
    };

    # Ensure proper window focus and activation
    "org/gnome/desktop/wm/preferences" = {
      focus-new-windows = "strict";
      auto-raise = true;
    };

    # Shell configuration and extensions
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
      enabled-extensions = [
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"  # Required for auto workspace assignment
      ];
      disable-user-extensions = false;
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":minimize,maximize,close";
      resize-with-right-button = true;
      auto-maximize = true;
    };

    # Configure automatic workspace assignment (requires auto-move-windows extension)
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "firefox.desktop:1"              # Move Firefox to workspace 1
        "org.keepassxc.KeePassXC.desktop:1"  # Move KeePassXC to workspace 1
        "obsidian.desktop:2"            # Move Obsidian to workspace 2
        "vesktop.desktop:3"             # Move Vesktop to workspace 3
      ];
    };

    # Desktop icons settings
    "org/gnome/shell/extensions/ding" = {
      show-home = false;
      show-trash = true;
    };

    # Dock settings
    "org/gnome/shell/extensions/dash-to-dock" = {
      click-action = "minimize";
      dock-fixed = true;
      extend-height = true;
      dock-position = "LEFT";
    };

    # Custom keybindings
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Launch Terminal";
    };

    # Session settings
    "org/gnome/desktop/session" = {
      idle-delay = "uint32 0";
    };
  };

  # Configure XDG autostart entries
  xdg.configFile = {
    "autostart/firefox.desktop".source = "${pkgs.firefox}/share/applications/firefox.desktop";

    "autostart/keepassxc.desktop".text = ''
      [Desktop Entry]
      Name=KeePassXC
      GenericName=Password Manager
      Exec=env QT_QPA_PLATFORMTHEME=gnome-dark keepassxc
      Icon=keepassxc
      StartupWMClass=keepassxc
      Terminal=false
      Type=Application
      Version=1.0
      Categories=Utility;Security;Qt;
      MimeType=application/x-keepass2;
    '';

    "autostart/obsidian.desktop".text = ''
      [Desktop Entry]
      Name=Obsidian
      Exec=obsidian --force-device-scale-factor=1 %U
      Terminal=false
      Type=Application
      Icon=obsidian
      StartupWMClass=obsidian
      Comment=Obsidian
      Categories=Office;
      MimeType=x-scheme-handler/obsidian;
      X-GNOME-UsesNotifications=true
      StartupNotify=true
    '';

    "autostart/vesktop.desktop".source = "${pkgs.vesktop}/share/applications/vesktop.desktop";
  };

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    gnome-shell-extensions
    adwaita-icon-theme
    nerd-fonts.jetbrains-mono
    libcanberra-gtk3

    # Wayland utilities
    wl-clipboard
    grim
    slurp
    wf-recorder
    wlr-randr
    qt6.qtwayland
    xdg-desktop-portal-wlr

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gnome-dark";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    ELECTRON_ENABLE_STACK_DUMPING = "1";
  };
}
