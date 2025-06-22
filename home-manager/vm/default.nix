{ pkgs, ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # VM-specific packages (moved from system configuration)
  home.packages = with pkgs; [
    # Add any other VM-specific packages
    gnome.gnome-console # Ptyxis terminal
  ];

  # Configure Firefox (moved from system configuration)
  programs.firefox = {
    enable = true;
  };

  # VM-specific session variables
  home.sessionVariables = {
    # Additional VM-specific variables can go here
    # These will be merged with those from common
  };
}
