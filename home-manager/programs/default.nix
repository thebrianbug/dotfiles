{ config, pkgs, ... }:

{
  programs.vscode = let
    defaultExtensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      saoudrizwan.claude-dev
      jnoortheen.nix-ide
    ];
    
    contextAwareKeybindings = let
      fileFinderOutsideTerminal = {
        key = "ctrl+p";
        command = "workbench.action.quickOpen";
        when = "!terminalFocus && !inQuickOpen";
      };
      commandHistoryInTerminal = {
        key = "ctrl+p";
        command = "workbench.action.terminal.selectPrevious";
        when = "terminalFocus";
      };
    in [
      fileFinderOutsideTerminal  # Ctrl+P opens file finder when not in terminal
      commandHistoryInTerminal   # Ctrl+P navigates history when in terminal
    ];
  in {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = defaultExtensions;
      keybindings = contextAwareKeybindings;
    };
  };

  programs.git = {
    enable = true;
    userName = "Brian Bug";
    userEmail = "thebrianbug@gmail.com";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  programs.bash.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    # Wayland-specific
    MOZ_ENABLE_WAYLAND = "1";  # Keep Firefox on Wayland
    # QT_QPA_PLATFORM = "wayland";  # Let Qt apps decide their platform
    QT_STYLE_OVERRIDE = "Adwaita-Dark";  # Keep dark theme
    # QT_AUTO_SCREEN_SCALE_FACTOR = "1";  # Let Qt handle scaling automatically
    # SDL_VIDEODRIVER = "wayland";  # Let SDL choose its driver
    # _JAVA_AWT_WM_NONREPARENTING = "1";  # Only needed for certain Java apps
    XDG_SESSION_TYPE = "wayland";  # Keep basic Wayland session type
    XDG_CURRENT_DESKTOP = "GNOME";  # Keep GNOME desktop identification
    # Electron Wayland support
    # NIXOS_OZONE_WL = "1";  # Let Electron apps choose their backend
    # ELECTRON_OZONE_PLATFORM_HINT = "wayland";  # Don't force Wayland
    # ELECTRON_ENABLE_STACK_DUMPING = "1";  # Debug feature, not needed
    # OZONE_PLATFORM = "wayland";  # Don't force Wayland
    # HiDPI scaling fixes
    # ELECTRON_FORCE_DEVICE_SCALE_FACTOR = "1";  # Let apps handle their own scaling
    # GDK_SCALE = "1";  # Let GTK handle scaling
    # GDK_DPI_SCALE = "1";  # Let GTK handle DPI
    # WINIT_X11_SCALE_FACTOR = "1";  # Not needed for Wayland
  };

  programs.home-manager.enable = true;

  # KeePassXC dark theme configuration
  xdg.configFile."keepassxc/keepassxc.ini".text = ''
    [General]
    ConfigVersion=2

    [GUI]
    ApplicationTheme=dark
  '';
}
