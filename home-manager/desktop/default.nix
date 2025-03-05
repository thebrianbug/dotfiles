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
    "autostart/firefox.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Firefox
      Exec=${pkgs.firefox}/bin/firefox
      X-GNOME-Autostart-enabled=true
    '';

    "autostart/keepassxc.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=KeePassXC
      Exec=${pkgs.keepassxc}/bin/keepassxc
      X-GNOME-Autostart-enabled=true
    '';

    "autostart/obsidian.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Obsidian
      Exec=${pkgs.obsidian}/bin/obsidian
      X-GNOME-Autostart-enabled=true
    '';

    "autostart/vesktop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Vesktop
      Exec=${pkgs.vesktop}/bin/vesktop
      X-GNOME-Autostart-enabled=true
    '';
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
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    ELECTRON_ENABLE_STACK_DUMPING = "1";
  };
}
