{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Languages and runtimes
    python39
    nodejs_20

    # Node.js packages
    nodePackages.live-server
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.typescript

    # Database tools
    dbeaver-bin

    # CLI tools
    fzf
    rclone

    # Nix tools
    nil           # Nix Language Server
    nix-tree      # Visualize nix dependencies
    nix-direnv    # Project-specific environments
    alejandra     # Modern Nix formatter
  ];
}
