{ ... }:

{
  # Import common configurations
  imports = [
    ../common
  ];

  # Enable genericLinux support for Fedora
  targets.genericLinux.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Fedora-specific packages can be added here when needed
  # home.packages = [
  #   pkgs.some-fedora-specific-package
  # ];

  # Any Fedora-specific overrides can go here
}
