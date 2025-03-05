{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Container management
    podman
    podman-compose

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

    # IDE
    code-cursor

    # Docker compatibility
    (writeShellScriptBin "docker" ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec podman "$@"
    '')
    (writeShellScriptBin "docker-compose" ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec podman-compose "$@"
    '')
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    DOCKER_SOCK = "$XDG_RUNTIME_DIR/podman/podman.sock";
  };
}
