# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot = {
    # EFI Partition Management: Limit bootloader generations for small EFI partitions
    # If your EFI partition is small (e.g., 260 MiB), you might be limited to
    # keeping only one NixOS generation to avoid running out of space.
    # This limits your rollback capabilities directly from the bootloader.
    # For more generations, consider expanding your EFI partition.
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        device = "nodev"; # Required for EFI install
      };

      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
    };

    # Use latest stable kernel for best hardware support
    # Note: Modern kernels auto-load most required modules for ASUS laptops
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "nvidia-drm.modeset=1" # Enable NVIDIA DRM for better compatiblity
      "amd_pstate=active" # Essential power management for AMD CPUs
    ];

    # Only declare modules that don't auto-load on modern kernels
    kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm" # NVidia
      "mt7921e"
      "mt7922e" # MediaTek WiFi (often needs manual loading)
      "i2c_hid_acpi" # Required for some touchpad/touchscreen devices
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

    # Audio setup (modern replacement for PulseAudio)
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = true; # Professional audio support
    };

    # Display services
    colord.enable = true; # Color management for ProArt display
    geoclue2.enable = true; # Location-based features

    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ]; # Load NVidia Driver
    };
  };

  systemd.services.supergfxd.path = [ pkgs.pciutils ]; # Manually add pciutlis to supergfxd path

  # Essential environment variables for NVIDIA+Wayland
  environment.variables = {
    GBM_BACKEND = "nvidia-drm"; # Required for GNOME Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # OpenGL vendor selection
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes cursor issues in Wayland
  };

  # System diagnostic and hardware tools
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    inxi
    glxinfo # Hardware Debugging

    iio-sensor-proxy # Auto-rotation, light sensor
    nvidia-offload  # helper for NVIDIA Prime
  ];

  # Firmware for hardware components
  hardware = {

    # NVIDIA configuration for RTX 4070
    nvidia = {
      modesetting.enable = true; # Required for Wayland compatibility
      powerManagement = {
        enable = false;
        finegrained = false; # Better power management for laptops, disabled temporarily to debug card issue
      };
      nvidiaSettings = true;
      # forceFullCompositionPipeline = true; # Eliminates screen tearing
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Set up prime offloading for demanding apps only
      prime = {
        offload.enable = true;
        sync.enable = false;
        # PCI bus IDs for hybrid graphics
        amdgpuBusId = "PCI:101:0:0"; # AMD GPU at 65:00.0
        nvidiaBusId = "PCI:100:0:0"; # NVIDIA GPU at 64:00.0
      };
      open = false; # Prefer propritary driver
    };

    enableAllFirmware = true; # Auto-detect needed firmware
    firmware = with pkgs; [
      linux-firmware # Broad hardware support
      sof-firmware # Better audio support
    ];

    # Enable hardware acceleration with Mesa support for AMD GPU
    graphics = {
      enable = true;
      enable32Bit = true; # Useful for 32 bit applications
      extraPackages = with pkgs; [
        # Basic Mesa drivers
        mesa
        # AMD specific packages
        amdvlk
        # OpenCL support
        rocmPackages.clr
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        # 32-bit support
        libva
        amdvlk
      ];
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Networking configuration
  networking.networkmanager.enable = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.brianbug = {
    isNormalUser = true;
    description = "Brian Bug";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = [
      # Add user-specific packages here if needed
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Configure keymap in X11 and Wayland
  # services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:swapcaps"; # Swap Caps Lock and Control

  # Ensure the same keymap is used in console
  console.useXkbConfig = true;

  # Swap Caps Lock and Control in GNOME
  environment.etc."gsettings/gnome-desktop-input-sources".text = ''
    [org.gnome.desktop.input-sources]
    xkb-options=['ctrl:swapcaps']
  '';

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
