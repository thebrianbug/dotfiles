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

  # Automatic screen brightness based on content
  services.wluma = {
    enable = true;
    settings = {
      # Adjust brightness smoothly
      capture.fps = 30;
      capture.size = 120;
      # Brightness adjustment settings
      brightness = {
        day = {
          sunrise = 1.0;     # Full brightness during day
          sunset = 0.7;      # Slightly dimmer at sunset
        };
        night = {
          sunrise = 0.7;     # Brighter at sunrise
          sunset = 0.5;      # Dimmer at night
        };
      };
    };
  };
}
