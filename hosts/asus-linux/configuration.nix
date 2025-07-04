# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot = {
    # EFI Partition Management: Limit bootloader generations for small EFI partitions
    # If your EFI partition is small (e.g., 260 MiB), you might be limited to
    # keeping only one NixOS generation to avoid running out of space.
    # This limits your rollback capabilities directly from the bootloader.
    # For more generations, consider expanding your EFI partition.
    loader.systemd-boot = {
      enable = true; # Allow NixOS to write its bootloader to the EFI partition
      configurationLimit = 1; # Keep only one generation to save space
    };

    # Use latest stable kernel for best hardware support
    # Note: Modern kernels auto-load most required modules for ASUS laptops
    kernelPackages = pkgs.linuxPackages_latest;

    # Essential power management for AMD CPUs
    kernelParams = [ "amd_pstate=active" ];

    # Only declare modules that don't auto-load on modern kernels
    kernelModules = [
      "mt7921e" "mt7922e"  # MediaTek WiFi (often needs manual loading)
      "i2c_hid_acpi"       # Required for some touchpad/touchscreen devices
    ];
  };

  # Services configuration
  services = {
    # ASUS hardware control
    # Unified GPU control (replaces older solutions)
    supergfxd.enable = true;

    # System control daemon (fan curves, keyboard lighting, etc.)
    asusd = {
      enable = true;
      enableUserService = true;
    };

    # Power management (do not use TLP with power-profiles-daemon + asusd)
    power-profiles-daemon.enable = true;

    # Input devices
    libinput.enable = true; # Touchpad support
    gestures.enable = true; # Enhanced touchpad/touchscreen gesture support
    iio-sensor-proxy.enable = true; # Auto-rotation, light sensor

    # Audio setup (modern replacement for PulseAudio)
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = true;  # Professional audio support
    };

    # Display services
    colord.enable = true;    # Color management for ProArt display
    geoclue2.enable = true;  # Location-based features

    # GNOME desktop with Wayland (for best HDR support)
    xserver = {
      desktopManager.gnome.enable = true;
      displayManager.gdm.wayland = true;
    };
  };

  # NVIDIA configuration for RTX 4070
  hardware.nvidia = {
    modesetting.enable = true; # Required for Wayland compatibility
    powerManagement = {
      enable = true;
      finegrained = true; # Better power management for laptops
    };
    forceFullCompositionPipeline = true; # Eliminates screen tearing
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Essential environment variables for NVIDIA+Wayland
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";        # Required for GNOME Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # OpenGL vendor selection
    WLR_NO_HARDWARE_CURSORS = "1";     # Fixes cursor issues in Wayland
  };

  # System diagnostic and hardware tools
  environment.systemPackages = with pkgs; [
    pciutils usbutils inxi glxinfo
  ];

  # Firmware for hardware components
  hardware = {
    enableAllFirmware = true; # Auto-detect needed firmware
    firmware = with pkgs; [
      linux-firmware  # Broad hardware support
      sof-firmware    # Better audio support
    ];
  };

  # Networking configuration
  networking.networkmanager.enable = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

