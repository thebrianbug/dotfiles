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
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_STYLE_OVERRIDE = "Adwaita-Dark";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
    # Electron Wayland support
    NIXOS_OZONE_WL = "1";  # Forces Electron apps to use Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";  # Hint to use Wayland backend
    ELECTRON_ENABLE_STACK_DUMPING = "1";
    OZONE_PLATFORM = "wayland";
  };

  programs.home-manager.enable = true;

}
