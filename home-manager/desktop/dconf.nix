{ config, pkgs, ... }:

{
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
      toggle-fullscreen = ["<Super>f"];
    };
    
    # Window state preservation
    "org/gnome/mutter/wayland" = {
      restore-monitor-config = true;
    };

    # Application specific window rules
    "org/gnome/shell/extensions/auto-move-windows" = {
      focus-new-windows = true;
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
        "firefox.desktop"
        "org.gnome.Terminal.desktop"
        "obsidian.desktop"
        "vesktop.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "windsurf.desktop"
      ];
      enabled-extensions = [
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      ];
      disable-user-extensions = false;
    };

    # Interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      scaling-factor = 0;
      text-scaling-factor = 0.0;
    };

    # Workspace assignment
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "firefox.desktop:1"
        "obsidian.desktop:3"
        "org.keepassxc.KeePassXC.desktop:2"
        "vesktop.desktop:2"
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

    # Session settings
    "org/gnome/desktop/session" = {
      idle-delay = "uint32 0";
    };

    # Terminal configuration
    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
      theme-variant = "dark";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      audible-bell = false;
      background-color = "rgb(23, 20, 33)";
      foreground-color = "rgb(208, 207, 204)";
      use-system-font = true;
      use-theme-colors = false;
      visible-name = "Default";
      default-size-columns = 120;
      default-size-rows = 35;
    };

    # Terminal keyboard shortcut
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Launch Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
  };
}
