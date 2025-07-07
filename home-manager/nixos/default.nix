{ pkgs, ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # NixOS-specific packages
  home.packages = with pkgs; [
    # Any NixOS-specific packages would go here
    zoom-us
    teams-for-linux
  ];

  # Configure Zoom to not follow workspaces
  xdg.configFile."zoomus.conf".text = ''
    [General]
    enableMiniWindow=false
  '';

  # Configure Home Manager to create backup files instead of failing when files exist
  home-manager.backupFileExtension = "backup";

  # NixOS-specific session variables
  home.sessionVariables = {
    # NixOS-specific variables can go here
    # On NixOS, many variables are better set via the system configuration
    # These will be merged with those from common
  };
}
