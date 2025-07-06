{ pkgs, ... }:

{
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

  programs.firefox = {
    enable = true;
    profiles = {
      bmcilw1 = {
        id = 0; # Primary profile
        isDefault = true;
        settings = {
          # Example settings for the profile
          "browser.startup.homepage" = "https://start.duckduckgo.com";
          "general.smoothScroll" = true;
          "privacy.trackingprotection.enabled" = true;
        };
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          darkreader
          df-youtube
          ublock-origin
        ];
      };
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
