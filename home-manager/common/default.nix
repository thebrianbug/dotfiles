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

      # Business tools
      teams-for-linux
      libreoffice

      # Entertainment
      musescore
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
          "privacy.trackingprotection.socialtracking.enabled" = true;
        };
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          darkreader
          youtube-recommended-videos
          ublock-origin
          vimium-c
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
