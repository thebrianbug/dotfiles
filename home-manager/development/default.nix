{ config, pkgs, ... }:

{
  imports = [
    ./docker.nix
  ];

  home.packages = with pkgs; [
    # Database tools
    dbeaver-bin

    # Languages and runtimes
    python39
    nodejs_20

    # Node.js packages
    nodePackages.live-server
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.typescript

    # CLI tools
    fzf
    rclone
  ];
}
