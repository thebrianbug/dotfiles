{ pkgs, ... }:

{
  # Common GNOME utilities useful across NixOS and VM environments
  home.packages = with pkgs; [
    gnome-tweaks
    gnome-shell-extensions
  ];
}
