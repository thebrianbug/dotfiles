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

    # Dev languages
    fzf
    python39
    nodejs
    nodePackages.live-server
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.npm
    nodePackages.typescript
  ];

  programs.vscode = {
    enable = true;
    # package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
    ];
  };

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
           

