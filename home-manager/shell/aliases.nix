{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      cl = "clear";
      gs = "git status";
      gp = "git pull";
      gg = "git push";
      gt = "git log -n 10 --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };
}
