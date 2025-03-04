{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      saoudrizwan.claude-dev
      jnoortheen.nix-ide
    ];
    profiles.default.keybindings = [
      {
        key = "ctrl+p";
        command = "workbench.action.terminal.sendSequence";
        args = { text = "\u001b[A"; };
        when = "terminalFocus";
      }
      {
        key = "ctrl+p";
        command = "workbench.action.quickOpen";
        when = "!terminalFocus";
      }
    ];
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

  home.sessionVariables.EDITOR = "nvim";

  programs.home-manager.enable = true;
}
