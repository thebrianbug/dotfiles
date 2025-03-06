{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      cl = "clear";
      gs = "git status";
      gp = "git pull";
      gg = "git push";
    };
  };
}
