{ config, pkgs, ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # VM-specific packages
  home.packages = with pkgs; [
    # Basic GNOME environment utilities that make sense in a VM
    gnome-tweaks
    gnome-shell-extensions
    
    # Development tools useful in a VM environment
    nixpkgs-fmt
    nil  # Nix language server
  ];
  
  # VM-specific session variables
  home.sessionVariables = {
    # Additional VM-specific variables can go here
    # These will be merged with those from common
  };
}
