{ ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # VM-specific packages
  home.packages = [
    # Any VM-specific packages would go here
  ];
  
  # VM-specific session variables
  home.sessionVariables = {
    # Additional VM-specific variables can go here
    # These will be merged with those from common
  };
}
