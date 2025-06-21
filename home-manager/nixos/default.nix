{ config, pkgs, ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # NixOS-specific packages
  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    gnome-shell-extensions
    
    # Basic development tools for NixOS
    nixpkgs-fmt
    nil  # Nix language server
  ];
  
  # NixOS-specific session variables
  home.sessionVariables = {
    # NixOS-specific variables can go here
    # On NixOS, many variables are better set via the system configuration
    # These will be merged with those from common
  };
}
