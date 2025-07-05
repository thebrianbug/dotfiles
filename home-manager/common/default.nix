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
      extensions = {
        extraExtensions = [
          (pkgs.fetchurl {
            url = "https://addons.mozilla.org/firefox/downloads/latest/distraction-free-youtube/latest.xpi";
            sha256 = "15fh4ga9wkp9m0599wrc5fa2411151bv2rgvw31jd1i0nn98b8dj";
          })
          (pkgs.fetchurl {
            url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
            sha256 = "040zzsis2fnvj2crxhknak5gz7q4mc8r3jj0mrzvb9is0s2l1j93";
          })
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
