{ config, pkgs, ... }:

{
  programs.gnome-terminal = {
    enable = true;
    profile = {
      "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        default = true;
        visibleName = "Default";
        # Tokyo Night theme colors (matching your previous wezterm theme)
        backgroundColor = "rgb(26,27,38)";
        foregroundColor = "rgb(192,202,245)";
        palette = [
          "rgb(21,22,30)" # black
          "rgb(247,118,142)" # red
          "rgb(158,206,106)" # green
          "rgb(224,175,104)" # yellow
          "rgb(122,162,247)" # blue
          "rgb(187,154,247)" # magenta
          "rgb(125,207,255)" # cyan
          "rgb(169,177,214)" # white
          "rgb(65,72,104)" # bright black
          "rgb(247,118,142)" # bright red
          "rgb(158,206,106)" # bright green
          "rgb(224,175,104)" # bright yellow
          "rgb(122,162,247)" # bright blue
          "rgb(187,154,247)" # bright magenta
          "rgb(125,207,255)" # bright cyan
          "rgb(192,202,245)" # bright white
        ];
        showScrollbar = false;
        font = "JetBrainsMono Nerd Font 11";
        scrollbackLines = 10000;
        transparencyPercent = 5;
      };
    };
  };
}
