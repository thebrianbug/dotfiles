{ pkgs, ... }:

{
  # this is internal compatibility configuration
  # for home-manager, don't change this!
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    obsidian
    discord
    vscode
    zoom-us
    google-chrome
  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };
  home.file = {
    ".config/discord/settings.json" = {
      text = "{ \"SKIP_HOST_UPDATE\": true }";
    };
  };
}

