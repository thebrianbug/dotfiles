{ config, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
  ];

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
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
  };

  programs.home-manager.enable = true;

  programs.alacritty.package = pkgs.alacritty;
}
