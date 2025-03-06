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
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Helper to generate outputs for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Nixpkgs instantiated for each system
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      # Home Manager configurations
      homeConfigurations = {
        "brianbug" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsFor.x86_64-linux;
          modules = [ ./home-manager/home.nix ];
          
          # Make system info available to modules
          extraSpecialArgs = {
            inherit supportedSystems;
          };
        };
      };

      # Development shell with helpful tools
      devShells = forAllSystems (system: {
        default = nixpkgsFor.${system}.mkShell {
          packages = with nixpkgsFor.${system}; [
            nixpkgs-fmt  # Nix code formatter
            nil         # Nix language server
          ];
        };
      });

      # Formatter for 'nix fmt'
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixpkgs-fmt);
    };
}
