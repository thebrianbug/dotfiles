{ config, pkgs, ... }:

{
  imports = [
    ./editors.nix
  ];

  programs.git = {
    enable = true;
    userName = "Brian Bug";
    userEmail = "thebrianbug@gmail.com";
  };

  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # KeePassXC dark theme configuration
  xdg.configFile."keepassxc/keepassxc.ini".text = ''
    [General]
    ConfigVersion=2

    [GUI]
    ApplicationTheme=dark
  '';
}
