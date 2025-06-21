{ ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # NixOS-specific packages
  home.packages = [
    # Any NixOS-specific packages would go here
  ];
  
  # NixOS-specific session variables
  home.sessionVariables = {
    # NixOS-specific variables can go here
    # On NixOS, many variables are better set via the system configuration
    # These will be merged with those from common
  };
}
