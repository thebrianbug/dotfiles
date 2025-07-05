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
    profiles.default = {
      extensions = [
        # Distraction Free YouTube (DF Tube)
        "https://addons.mozilla.org/firefox/downloads/latest/distraction-free-youtube/latest.xpi"
        # Dark Reader
        "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"
      ];
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
