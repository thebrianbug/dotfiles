{ config, pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./languages.nix
  ];
}
