{ config, pkgs, ... }:

{
  imports = [
    ./dconf.nix
    ./autostart.nix
  ];

  home.packages = with pkgs; [
    # System utilities
    gnome-tweaks
    gnome-shell-extensions
    adwaita-icon-theme
    nerd-fonts.jetbrains-mono
    libcanberra-gtk3

    # Wayland utilities
    wl-clipboard
    grim
    slurp
    wf-recorder
    wlr-randr
    qt6.qtwayland
    xdg-desktop-portal-wlr

    # Applications
    keepassxc
    obsidian
    vesktop
    google-chrome
  ];
}
