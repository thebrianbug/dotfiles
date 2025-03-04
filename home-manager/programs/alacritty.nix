{ config, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "xterm-256color";
        WINIT_UNIX_BACKEND = "wayland";
      };
      window = {
        startup_mode = "Windowed";
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
        dimensions = {
          columns = 120;
          lines = 30;
        };
        dynamic_title = true;
        decorations = "full";
        class = {
          instance = "Alacritty";
          general = "Alacritty";
        };
      };
      terminal = {
        shell = {
          program = "${pkgs.bashInteractive}/bin/bash";
        };
      };

      colors = {
        primary = {
          background = "#1a1b26";
          foreground = "#c0caf5";
        };
        normal = {
          black = "#15161e";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#a9b1d6";
        };
        bright = {
          black = "#414868";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#c0caf5";
        };
      };
    };
  };
}
