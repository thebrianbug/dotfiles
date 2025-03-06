{ config, pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./editors.nix
    ./git.nix
    ./languages.nix
    ./terminal.nix
  ];
}
