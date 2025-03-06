{ config, pkgs, ... }:

{
  imports = [
    ./editors.nix
    ./git.nix
    ./terminal.nix
  ];

  # KeePassXC dark theme configuration
  xdg.configFile."keepassxc/keepassxc.ini".text = ''
    [General]
    ConfigVersion=2

    [GUI]
    ApplicationTheme=dark
  '';
}
