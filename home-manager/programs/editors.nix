{ config, pkgs, ... }:

let
  useVSCodium = false;  # Set to true to use VSCodium, false for Windsurf
in
{
  programs.vscode = let
    defaultExtensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      jnoortheen.nix-ide
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      prisma.prisma
      svelte.svelte-vscode
      bradlc.vscode-tailwindcss
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
    package = if useVSCodium then pkgs.vscodium else pkgs.windsurf;
    profiles.default = {
      extensions = defaultExtensions;
      keybindings = if useVSCodium then contextAwareKeybindings else [];
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
