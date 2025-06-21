{ pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic home configuration
  home = {
    username = "brianbug";
    homeDirectory = "/home/brianbug";
    stateVersion = "24.11"; # Required setting

    # Basic default packages useful everywhere
    packages = with pkgs; [
      # CLI utilities
      ripgrep
      fd
      jq
      wget
      curl
    ];

    # Common session variables
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  # Import shared component configurations
  imports = [
    ./editors.nix
    ./git.nix
    ./shell
    ./gnome.nix
    ./wayland.nix
    ./languages.nix
    ./podman.nix
    ./autostart.nix
  ];
}
