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
        "obsidian.desktop:2"            # Move Obsidian to workspace 2
        "org.keepassxc.KeePassXC.desktop:2"  # Move KeePassXC to workspace 2
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
    "bin/wait-for-env.sh" = {
      text = ''
      #!/bin/sh
      max_attempts=30
      required_vars="${lib.concatStringsSep " " (lib.attrNames config.home.sessionVariables)}"
      missing_vars=""

      for attempt in $(seq 1 $max_attempts); do
        missing_vars=""
        for var in $required_vars; do
          eval "val=\$$var"
          [ -z "$val" ] && missing_vars="$missing_vars $var"
        done
        
        if [ -z "$missing_vars" ]; then
          exec "$@"
        fi
        
        echo "Waiting for:$missing_vars (attempt $attempt/$max_attempts)"
        sleep 1
      done

      echo "Timed out waiting for:$missing_vars"
      exit 1
    '';
      executable = true;
    };

    "autostart/firefox.desktop".text = ''
      [Desktop Entry]
      Name=Firefox Web Browser
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh firefox %u
      Terminal=false
      Type=Application
      Icon=firefox
      StartupWMClass=firefox
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
    '';

    "autostart/obsidian.desktop".text = ''
      [Desktop Entry]
      Name=Obsidian
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh obsidian --force-device-scale-factor=1 --enable-features=UseOzonePlatform,WaylandWindowDecorations %U
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

    "autostart/vesktop.desktop".text = ''
      [Desktop Entry]
      Name=Vesktop
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh vesktop
      Terminal=false
      Type=Application
      Icon=vesktop
      StartupWMClass=vesktop
      Categories=Network;InstantMessaging;
      StartupNotify=true
    '';

    "autostart/keepassxc.desktop".text = ''
      [Desktop Entry]
      Name=KeePassXC
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh keepassxc
      Terminal=false
      Type=Application
      Icon=keepassxc
      StartupWMClass=keepassxc
      Categories=Utility;Security;Qt;
      StartupNotify=true
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

}
