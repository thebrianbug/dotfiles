{
  description = "Home Manager configuration for multiple environments";

  inputs = {
    # Package sources
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NUR packages
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nur,
      ...
    }:
    let
      # System configuration
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # NixOS configurations
      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/vm/configuration.nix
            # Include home-manager as NixOS module for the VM
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.brianbug = import ./home-manager/vm;
              # Add NUR overlay for Firefox extensions
              nixpkgs.overlays = [ nur.overlay ];
            }
          ];
        };

        asus-linux = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit nur;
          };
          modules = [
            ./hosts/asus-linux/configuration.nix
            {
              nixpkgs.overlays = [ nur.overlays.default ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.brianbug = import ./home-manager/nixos;
            }
          ];
        };
      };

      # Home Manager configurations
      homeConfigurations = {
        # Main Fedora configuration
        "brianbug" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/fedora ];
        };

        # VM-specific configuration (for standalone use)
        "brianbug-vm" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/vm ];
        };

        # NixOS configuration (for standalone use)
        "brianbug-nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/nixos ];
        };
      };

      # Development shell with helpful tools
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixpkgs-fmt # Nix code formatter
          nil # Nix language server
        ];
      };

      # Formatter for 'nix fmt'
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
