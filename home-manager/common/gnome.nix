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
        "org.gnome.Ptyxis.desktop"
        "obsidian.desktop"
        "vesktop.desktop"
        "org.keepassxc.KeePassXC.desktop"
      ];
      enabled-extensions = [
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      ];
      disable-user-extensions = false;
    };

    # Auto-move windows extension configuration
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "firefox.desktop:1"
        "keepassxc.desktop:2"
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

    # Session settings
    "org/gnome/desktop/session" = {
      idle-delay = "uint32 0";
    };

    # Terminal configuration
    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
      theme-variant = "dark";
    };

    # Power management settings
    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      power-saver-profile-on-low-battery = true;
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-ac-type = "nothing";
    };
  };
}
