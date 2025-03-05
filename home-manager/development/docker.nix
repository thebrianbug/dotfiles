{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Container management
    podman
    podman-compose

    # Docker compatibility scripts
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
