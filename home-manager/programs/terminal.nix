{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Modern, fast terminal emulator with native UI
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = "12";
      background-opacity = "0.95";
    };
  };

}
