{ config, pkgs, ... }:

let
  repoRoot = builtins.toString ../..;
in
{
  # Common GNOME utilities and settings useful across all environments
  home.packages = with pkgs; [
    # GNOME utilities
    gnome-tweaks
    gnome-shell-extensions
    adwaita-icon-theme
    nerd-fonts.jetbrains-mono
    libcanberra-gtk3

    # Common applications for all hosts
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];

  # Create autostart file to enforce idle-delay at session startup
  # (Temporarily bug-fix for idle-delay not being disabled by dconf)
  # idle-delay is disabled as a bug fix for blank screen after suspend on resume
  # ~30-60 seconds after resume
  home.file.".config/autostart/force-idle-delay.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Force GNOME Idle Delay
    Exec=gsettings set org.gnome.desktop.session idle-delay 0
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
  '';

  # Common GNOME dconf settings
  dconf.settings = {
    # Mutter window and focus settings
    "org/gnome/mutter" = {
      edge-tiling = false;
      workspaces-only-on-primary = false;
      remember-window-size = false;
      focus-change-on-pointer-rest = false;
    };

    # Window state settings
    "org/gnome/shell/overrides" = {
      edge-tiling = false;
      attach-modal-dialogs = false;
    };

    # Window management keybindings
    "org/gnome/desktop/wm/keybindings" = {
      toggle-fullscreen = [ "<Super>f" ];
    };

    # Window state preservation
    "org/gnome/mutter/wayland" = {
      restore-monitor-config = true;
    };

    # Window focus preferences
    "org/gnome/desktop/wm/preferences" = {
      focus-new-windows = "strict";
      auto-raise = true;
      resize-with-right-button = true;
      auto-maximize = true;
    };

    # Shell configuration and extensions
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.mozilla.firefox.desktop"
        "firefox.desktop"
        "gnome-console.desktop"
        "org.gnome.Ptyxis.desktop"
        "obsidian.desktop"
        "vesktop.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "windsurf.desktop"
        "musescore.desktop"
      ];
      enabled-extensions = [
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      ];
      disable-user-extensions = false;
    };

    # Auto-move windows extension configuration
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "org.mozilla.firefox.desktop:1"
        "org.keepassxc.KeePassXC.desktop:2"
        "vesktop.desktop:2"
        "obsidian.desktop:3"
      ];
    };

    # Interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };

    # Background settings
    "org/gnome/desktop/background" = {
      picture-uri = "file://${repoRoot}/assets/books-arts-wallpaper-1920x1080.jpg";
      picture-uri-dark = "file://${repoRoot}/assets/books-arts-wallpaper-1920x1080.jpg";
      picture-options = "zoom";
    };

    # Terminal configuration
    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
      theme-variant = "dark";
    };

    # idle-delay is disabled as a bug fix for
    # blank screen after suspend on resume ~30-60 seconds after resume
    # Session settings
    "org/gnome/desktop/session" = {
      idle-delay = "uint32 0";
    };

    # lock-enabled is disabled as a bug fix for
    # blank screen after suspend on resume ~30-60 seconds after resume
    # Screen saver settings
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      lock-delay = "uint32 0";
    };

    # Power management settings
    # Test to disable suspend on AC and battery
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "suspend"; # Re-enable suspend on AC
      sleep-inactive-ac-timeout = 900; # 15 minutes (900 seconds)
      sleep-inactive-battery-type = "suspend"; # Re-enable suspend on battery
      sleep-inactive-battery-timeout = 600; # 10 minutes (600 seconds)
      lid-close-ac-action = "suspend"; # Keep lid close behavior
      lid-close-battery-action = "suspend";
      power-saver-profile-on-low-battery = true; # Enable power-saver on low battery
      power-profiles-on-ac = "balanced"; # Use balanced mode when on AC power
      power-profiles-on-battery = "power-saver"; # Use power-saver mode when on battery
    };
  };
}
