{ pkgs, ... }:

{
  # Common development tools useful across all environments
  home.packages = with pkgs; [
    # Nix development tools
    nixpkgs-fmt
    nil  # Nix language server
  ];
}
