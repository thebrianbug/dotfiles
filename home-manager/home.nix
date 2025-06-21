{ config, pkgs, ... }:

{
  # Basic Home Manager configuration
  home = {
    username = "brianbug";
    homeDirectory = "/home/brianbug";
    stateVersion = "24.11"; # Please read the comment before changing.
  };

  # Import common configuration
  imports = [
    ./common
    
    # Host-specific configurations can be added here
    # Example: ./nixos or ./fedora depending on the host
  ];
}
