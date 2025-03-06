{
  description = "Home Manager configuration for Fedora Workstation";

  inputs = {
    # Package sources
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # System configuration
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      # Home Manager configurations
      homeConfigurations = {
        "brianbug" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/home.nix ];
        };
      };

      # Development shell with helpful tools
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixpkgs-fmt  # Nix code formatter
          nil         # Nix language server
        ];
      };

      # Formatter for 'nix fmt'
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
