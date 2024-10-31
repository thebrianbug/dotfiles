{ pkgs, ... }:

{
  # this is internal compatibility configuration
  # for home-manager, don't change this!
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    obsidian
    discord
    zoom-us
    google-chrome

    # Dev tools
    vscode
    nodePackages.typescript
    nodejs_20
    python39
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    #defaultKeymap = "vicmd";
    initExtra = ''
      bindkey -v
    '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };
  home.file = {
    ".config/discord/settings.json" = {
      text = "{ \"SKIP_HOST_UPDATE\": true }";
    };
  };
}
           

