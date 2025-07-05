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
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes cursor issues in Wayland
  };

  # System diagnostic and hardware tools
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    inxi
    glxinfo # Hardware Debugging

    iio-sensor-proxy # Auto-rotation, light sensor

    # NVIDIA offload helper script
    (pkgs.writeScriptBin "nvidia-offload" (builtins.readFile ./nvidia-offload.sh))
  ];

  # Firmware for hardware components
  hardware = {

    # NVIDIA configuration for RTX 4070
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable; # Use stable driver
      modesetting.enable = true; # Required for Wayland compatibility

      powerManagement = {
        enable = true;
        finegrained = true; # Better power management for laptops
      };

      nvidiaSettings = true;
      # forceFullCompositionPipeline = true; # Eliminates screen tearing

      # Set up prime offloading for demanding apps only
      prime = {
        offload.enable = true;
        sync.enable = false;

        # PCI bus IDs for hybrid graphics
        amdgpuBusId = "PCI:65:00:0";
        nvidiaBusId = "PCI:64:00:0";
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

  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

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

  nixpkgs.config.allowUnfree = true;

  # Swap Caps Lock and Control in GNOME
  environment.etc."gsettings/gnome-desktop-input-sources".text = ''
    [org.gnome.desktop.input-sources]
    xkb-options=['ctrl:swapcaps']
  '';

  services.printing.enable = true;

  system.stateVersion = "25.05"; # DO NOT CHANGE after install, see `man configuration.nix`
}
