{ pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Import shared component configurations
  imports = [
    ./editors.nix
    ./git.nix
    ./shell
    ./dev.nix
    ./gnome.nix
  ];

  # Basic default packages useful everywhere
  home.packages = with pkgs; [
    # CLI utilities
    ripgrep
    fd
    jq
    wget
    curl
  ];

  # Common session variables
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
