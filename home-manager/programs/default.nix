{ config, pkgs, ... }:

let
  useWindsurf = true;  # Set to false to use VSCodium, true for Windsurf
in
{
  programs.vscode = let
    defaultExtensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      jnoortheen.nix-ide
    ] ++ (if (!useWindsurf) then [
      saoudrizwan.claude-dev
      supermaven.supermaven
    ] else []);
    
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
    package = if useWindsurf then pkgs.windsurf else pkgs.vscodium;
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
    MOZ_ENABLE_WAYLAND = "1";  # Enable Wayland support in Firefox
    QT_QPA_PLATFORM = "wayland;xcb";  # Prefer Wayland but fallback to X11
    QT_STYLE_OVERRIDE = "Adwaita-Dark";  # Keep dark theme
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";  # Enable automatic scaling
    SDL_VIDEODRIVER = "wayland,x11";  # Prefer Wayland but fallback to X11
    XDG_SESSION_TYPE = "wayland";  # Indicate Wayland session
    XDG_CURRENT_DESKTOP = "GNOME";  # Keep GNOME desktop identification
    # Electron Wayland support - more permissive
    ELECTRON_OZONE_PLATFORM_HINT = "auto";  # Let Electron choose best platform
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
