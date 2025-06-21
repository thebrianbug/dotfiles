{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Languages and runtimes
    python3
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
    nil # Nix Language Server
    nix-tree # Visualize nix dependencies
    nix-direnv # Project-specific environments
    nixfmt-classic # Nix formatter
  ];
}
