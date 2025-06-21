{
  config,
  lib,
  ...
}:

{
  # Import this file into common/default.nix
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

    "autostart/clipman.desktop".text = ''
      [Desktop Entry]
      Name=Clipman
      Comment=Clipboard Manager for Wayland
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh wl-paste -t text --watch clipman store --no-persist
      Terminal=false
      Type=Application
      Icon=edit-paste
      StartupWMClass=clipman
      Categories=Utility;
      StartupNotify=true
    '';

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
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh obsidian --enable-features=WaylandWindowDecorations --enable-webrtc-pipewire-capturer --enable-gpu-rasterization --enable-zero-copy %U
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
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh vesktop --enable-features=WaylandWindowDecorations --enable-webrtc-pipewire-capturer --enable-gpu-rasterization --enable-zero-copy
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
      Exec=${config.home.homeDirectory}/.config/bin/wait-for-env.sh keepassxc --enable-features=WaylandWindowDecorations --enable-webrtc-pipewire-capturer --enable-gpu-rasterization --enable-zero-copy
      Terminal=false
      Type=Application
      Icon=keepassxc
      StartupWMClass=keepassxc
      Categories=Utility;Security;Qt;
      StartupNotify=true
    '';
  };
}
