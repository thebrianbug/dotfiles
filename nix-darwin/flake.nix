{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
         vim
         curl
         gitAndTools.gitFull
         mkalias
         obsidian
         discord
      ];

      homebrew = {
        enable = true;
        casks = [
          "firefox"
          "keepassxc"
        ];
        onActivation.cleanup = "zap";
      };

      nixpkgs.config.allowUnfree = true;

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina

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
           { HIDKeyboardModifierMappingSrc = 30064771296; HIDKeyboardModifierMappingDst = 30064771129; }
         ];
      };

      # Add Applications to Spotlight hack
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

    };
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
            # User owning Homebrew prefix
            user = "brianmcilwain";
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Brians-MacBook-Pro".pkgs;
  };
}
