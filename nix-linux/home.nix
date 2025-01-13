{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brianbug";
  home.homeDirectory = "/home/brianbug";

  nixpkgs.config.allowUnfree = true;
  targets.genericLinux.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.wl-clipboard # Wayland clipboard access
    pkgs.gnome-tweaks

    pkgs.keepassxc
    pkgs.obsidian
    pkgs.vesktop # Replacement for pkgs.discord

    pkgs.google-chrome

    pkgs.rclone
    # pkgs.zoom-us # Not launching

    # Dev
    pkgs.fzf
    pkgs.python39
    pkgs.nodejs_20
    pkgs.nodePackages.live-server
    pkgs.nodePackages.nodemon
    pkgs.nodePackages.prettier
    # pkgs.nodePackages.npm
    pkgs.nodePackages.typescript
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
    ];
  };

  home.file = {
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/brianbug/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Enable X server services
  #services.xserver.enable = true;

  # Configure your window manager or desktop environment
  xsession.enable = true;
 # Set the window manager command to "gnome-session" for GNOME (GNOME handles window management)
  xsession.windowManager.command = "gnome-session";

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
	"obsidian.desktop"
	"vesktop.desktop"
	"org.keepassxc.KeePassXC.desktop"
      ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs.git = {
    enable = true;
    userName = "Brian Bug";
    userEmail = "thebrianbug@gmail.com";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
