{ config, pkgs, ... }:

{
  # Basic Home Manager configuration
  home = {
    username = "brianbug";
    homeDirectory = "/home/brianbug";
    stateVersion = "24.11"; # Please read the comment before changing.
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable generic Linux support
  targets.genericLinux.enable = true;

  # Import modular configurations
  imports = [
    ./desktop
    ./development
    ./programs
  ];
}
