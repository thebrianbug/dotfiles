{ ... }:

let
  # For VM detection, we'll use a hostname-based approach
  # You can rename your VM to include 'vm' in the hostname or use another approach
  isVM =
    let
      hostname = builtins.readFile "/etc/hostname";
    in
    # Check if 'vm' appears in the hostname (case insensitive)
    builtins.match ".*[vV][mM].*" hostname != null;

  # Alternative approaches:
  # 1. Create a marker file and check for it:
  # isVM = builtins.pathExists "/etc/vm-marker";
  #
  # 2. Check for specific VM-related files:
  # isVM = builtins.pathExists "/sys/class/dmi/id/product_name" &&
  #        builtins.match ".*[vV][mM].*" (builtins.readFile "/sys/class/dmi/id/product_name") != null;

  # Determine if we're on NixOS by checking for /etc/NIXOS file
  isNixOS = builtins.pathExists "/etc/NIXOS";

  # Choose the appropriate host module based on system detection
  # VM detection takes priority over NixOS detection
  hostModule =
    if isVM then
      ./vm
    else if isNixOS then
      ./nixos
    else
      ./fedora; # Default to fedora for all other systems
in
{
  # Basic Home Manager configuration
  home = {
    username = "brianbug";
    homeDirectory = "/home/brianbug";
    stateVersion = "24.11"; # Please read the comment before changing.
  };

  # Import common configuration and host-specific module
  imports = [
    ./common
    hostModule # This will be either ./nixos, ./vm, or ./fedora
  ];
}
