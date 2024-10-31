{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
    }:
    let
      spotlightApplications = import ./spotlight-applications.nix;

      configuration =
        { pkgs, config, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            home-manager
            vim
            curl
            gitAndTools.gitFull
            mkalias
            docker-client
          ];

          homebrew = {
            enable = true;
            casks = [
              "firefox"
              "keepassxc"
              "google-drive"
            ];
            onActivation = {
              cleanup = "zap";
              autoUpdate = true;
              upgrade = true;
            };
          };

          nixpkgs.config.allowUnfree = true;

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "x86_64-darwin";

          # Use TouchID for sudo
          security.pam.enableSudoTouchIdAuth = true;

          # System defaults for macOS preferences
          system.defaults = {
            dock.autohide = true; # Hide mac dock
            dock.mru-spaces = false; # No auto-rearrange spaces
            dock.persistent-apps = [
              "/System/Applications/Mail.app"
              "${pkgs.discord}/Applications/Discord.app"
              "/Applications/Firefox.app"
              "/Applications/KeePassXC.app"
              "${pkgs.obsidian}/Applications/Obsidian.app"
              "${pkgs.vscode}/Applications/Visual Studio Code.app"
            ];

            # Disable hot corners
            dock."wvous-tl-corner" = 1;
            dock."wvous-tr-corner" = 1;
            dock."wvous-bl-corner" = 1;
            dock."wvous-br-corner" = 1;

            # Specifies apps that should always be pinned to the macOS dock.
            # Alacritty and Obsidian are specified through Nix packages (using `${pkgs}` syntax),
            # while other applications are provided by absolute paths.

            loginwindow.GuestEnabled = false; # Disables guest login
            NSGlobalDomain.AppleICUForce24HourTime = true; # Forces 24-hour time format
            NSGlobalDomain.AppleInterfaceStyle = "Dark"; # Sets the interface to Dark mode
            NSGlobalDomain.KeyRepeat = 2; # Sets the key repeat rate
            finder.AppleShowAllExtensions = true; # Show all extensions
            finder.FXPreferredViewStyle = "clmv"; # Finder column view
            screencapture.location = "~/Pictures/screenshots";
            screensaver.askForPasswordDelay = 10;
          };

          # Enable Linux builder for building GNU/Linux binaries
          nix.linux-builder.enable = true;

          # Enable keyboard mappings and remap Caps Lock to Control
          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToControl = true;

            # Custom key mapping to make Control act as Caps Lock
            userKeyMapping = [
              {
                HIDKeyboardModifierMappingSrc = 224;
                HIDKeyboardModifierMappingDst = 57;
              }
            ];
          };

          # Use the imported spotlight script for activation
          system.activationScripts.applications.text = spotlightApplications { pkgs = pkgs; config = config; };

          users.users.brianmcilwain = {
            name = "brianmcilwain";
            home = "/Users/brianmcilwain";
          };

        };
      homeconfig = import ./home.nix;
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."Brians-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "brianmcilwain";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.brianmcilwain = homeconfig;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Brians-MacBook-Pro".pkgs;
    };
}
