# NixOS Installation Guide: ASUS ProArt P16

This guide provides step-by-step instructions for installing NixOS on an ASUS laptop, using configurations from this dotfiles repository. It covers both manual installation and the Calamares installer.

This guide has been tested with the ASUS ProArt P16 (H7606 series, including H7606WI with AMD Ryzen AI 9 HX 370, NVIDIA RTX 4070, MediaTek MT7922 WiFi, and 4K OLED touchscreen) and is current for **NixOS 25.05 "Warbler"**. It should work for most ASUS laptops, including ROG series. Verify compatibility for other models in the [NixOS Hardware Configuration Database](https://github.com/NixOS/nixos-hardware).

## For New Users

If you’re new to NixOS, use the Calamares graphical installer for simplicity. Refer to the [Zero to Nix Guide](https://zero-to-nix.com/) for basics. If errors occur during commands like `nixos-rebuild switch`, check `/etc/nixos/configuration.nix` for syntax errors and run `journalctl -p 3 -xb` for logs.

## Prerequisites

- NixOS installation media (**25.05 "Warbler"** recommended for the 2024 ProArt P16 H7606WI, as it includes a newer kernel and improved hardware support for recent AMD CPUs and NVIDIA GPUs).
- Internet connection
- Basic knowledge of NixOS and the command line

## Pre-Installation Steps

### Backup Proprietary eSupport Drivers

If Windows is installed, consider backing up proprietary ASUS drivers. While this guide focuses on dual-booting, this backup is useful if you ever decide to remove Windows entirely or need to run it in a virtual machine:

1.  In Windows, copy the entire `C:\eSupport` folder to external storage.

### Disable Secure Boot

**IMPORTANT FOR DUAL BOOT USERS**: If Windows BitLocker is enabled, disable it first, or your data will become inaccessible\!

1.  Press DEL repeatedly during boot to enter UEFI setup.
2.  Press F7 for advanced mode.
3.  Navigate to Security → Secure Boot Control → Disable.
4.  Save and exit.

### Use the Laptop Screen

Disconnect external displays during installation to avoid unpredictable behavior with graphics switching.

### Switch to Hybrid Mode on Windows (2022+ Models)

For 2022 or newer ASUS models, including the H7606WI, switch to Hybrid graphics mode in Windows to prevent potential issues during the NixOS installation:

1.  Open the MyASUS app, go to "Customization" → "GPU Settings," and select "Hybrid Mode" (or "Optimus Mode").
2.  Save changes and reboot before installing NixOS.

## Partition Overview

Before installation, review the disk partitions and what to keep for dual-booting with Windows:

| Partition   | Filesystem | Label    | Type                         | Purpose                              | Keep?                  |
| :---------- | :--------- | :------- | :--------------------------- | :----------------------------------- | :--------------------- |
| `nvme0n1p1` | vfat       | SYSTEM   | EFI System Partition         | Bootloader (shared Fedora + Windows) | ✅ Yes                 |
| `nvme0n1p2` | _(none)_   | _(none)_ | Microsoft Reserved Partition | Required for Windows (no FS)         | ✅ Yes                 |
| `nvme0n1p3` | ntfs       | OS       | Windows System               | Main Windows installation            | ✅ Yes                 |
| `nvme0n1p4` | ntfs       | RECOVERY | Windows Recovery Environment | Recovery tools/partition             | ✅ Yes (for dual-boot) |
| `nvme0n1p5` | vfat       | MYASUS   | ASUS preinstalled tools      | Manufacturer apps/drivers            | ✅ Yes (for dual-boot) |

Existing Linux partitions (e.g., Fedora’s `/boot` or root) can be safely removed and replaced with NixOS partitions.

## Disk Encryption (Optional)

> **Note**: Skip this section if you don’t need encryption. Proceed to standard installation.

This guide covers LUKS Full Disk Encryption, requiring a passphrase at boot.

### Implementing Disk Encryption

#### With Calamares Installer

The Calamares installer offers an encryption option during partitioning:

1.  Check "Encrypt system" when creating the root partition.
2.  Set a strong encryption passphrase.
3.  The installer handles LUKS setup automatically.

#### With Manual Installation

After creating partitions but before formatting:

1.  Set up LUKS2 encryption on your root partition (e.g., `/dev/nvme0n1p7`). You’ll be asked to set a passphrase.

    ```bash
    cryptsetup luksFormat --type luks2 /dev/nvme0n1p7

    # Open the encrypted partition
    cryptsetup luksOpen /dev/nvme0n1p7 cryptroot
    ```

    > **Note**: LUKS2 offers better security and is standard.

2.  Format the opened LUKS device:

    ```bash
    # For BTRFS (recommended)
    mkfs.btrfs /dev/mapper/cryptroot
    # OR for ext4
    # mkfs.ext4 /dev/mapper/cryptroot
    ```

3.  Mount the opened LUKS device:

    ```bash
    mount /dev/mapper/cryptroot /mnt
    ```

4.  After installing NixOS and generating your `hardware-configuration.nix`, add the following to your main `configuration.nix`:

    ```nix
    boot.initrd.luks.devices = {
      "cryptroot" = {
        device = "/dev/disk/by-uuid/YOUR-LUKS-PARTITION-UUID"; # Replace with the actual UUID of /dev/nvme0n1p7
        preLVM = true;
      };
    };
    ```

    To get the UUID of your LUKS-formatted partition (`/dev/nvme0n1p7` in this example):

    ```bash
    ls -la /dev/disk/by-uuid/
    ```

    Example output, where `9abc-1234` would be the UUID for `/dev/nvme0n1p7`:

    ```
    lrwxrwxrwx 1 root root 10 Jun 28 13:00 1234-ABCD -> ../../nvme0n1p1
    lrwxrwxrwx 1 root 10 Jun 28 13:00 9abc-1234 -> ../../nvme0n1p7
    ```

#### TPM-Based Encryption (Optional)

The ProArt P16 H7606WI has a TPM 2.0 chip, which can be used to unlock the LUKS partition automatically during boot without manual passphrase entry:

1.  Ensure TPM is enabled in UEFI setup (BIOS).

2.  Install required tools in your `configuration.nix`:

    ```nix
    environment.systemPackages = with pkgs; [
      clevis
      tpm2-tools
    ];
    ```

3.  After rebuilding and booting into your system, bind the LUKS partition to TPM. Use the _raw device path_ here, not the UUID or opened mapper device:

    ```bash
    sudo clevis luks bind -d /dev/nvme0n1p7 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
    ```

4.  Update your `configuration.nix` for automatic unlocking:

    ```nix
    boot.initrd.luks.devices."cryptroot" = {
      device = "/dev/disk/by-uuid/YOUR-LUKS-PARTITION-UUID"; # Replace with the actual UUID
      preLVM = true;
    };
    boot.initrd.systemd.enable = true;
    boot.initrd.clevis.enable = true;
    ```

    **Warning**: TPM unlocking is an advanced feature. Test it thoroughly after setup and **always maintain a passphrase as a backup**. System updates, especially firmware changes, or changes to the boot environment (e.g., adding/removing boot entries) may require re-binding the TPM.

### Notes on Encryption and Dual-Boot

- NixOS encryption is independent of Windows BitLocker.
- You can encrypt NixOS partitions with or without Secure Boot enabled.
- For maximum security, consider encrypting both Windows (BitLocker) and NixOS partitions.

## Step 1: Base NixOS Installation

### Option A: Using Calamares Installer (Graphical)

1.  Boot from the NixOS installation media (**25.05 "Warbler"**).
2.  Open the Calamares installer via the "Install System" icon.
3.  Follow initial setup steps (language, location, keyboard).
4.  In the partitioning section:
    - Select **Manual partitioning** for precise control.
    - **Do NOT format or delete** `nvme0n1p1` through `nvme0n1p5` if preserving Windows.
    - Delete existing Linux partitions (e.g., Fedora’s) to free up space.
    - Create new NixOS partitions in the freed space:
      - If needed, a separate `/boot` partition (ext4, \~512MB).
      - A **swap partition** (recommended: 32GB for the H7606WI’s 32GB RAM to handle memory-intensive tasks like video editing or 3D rendering). Note that full hibernation may be unreliable on this model due to firmware limitations; prioritize suspend-to-idle.
      - A root partition (`/`) using the remaining space (recommended: BTRFS or ext4).
      - **Important for BTRFS**: Calamares formats BTRFS but does not create subvolumes. It's highly recommended to perform a manual installation if you prefer BTRFS subvolumes from the start, or follow the post-installation steps below to set them up.
    - Mount `nvme0n1p1` (your existing EFI partition) at `/boot/efi` but **do NOT format it**.
5.  Continue with the installer:
    - Create your user account.
    - Set passwords.
    - Review and confirm settings.
6.  Complete installation and reboot.

### Post-Installation BTRFS Setup (Calamares)

Calamares installs directly to the BTRFS root (`subvolid=0`) and doesn’t create separate subvolumes for `/home` or `/nix`. To leverage BTRFS features like snapshots more effectively, you can set up subvolumes manually. This process involves moving existing data, so ensure you have a backup if this is a critical system.

1.  Boot into your new NixOS system.

2.  Create subvolumes and move data (this process takes time and disk space):

    ```bash
    # Login as root or use sudo
    sudo -i

    # Create a temporary mount point
    mkdir /mnt/btrfs-root

    # Mount the BTRFS partition (replace /dev/nvme0n1p7 with your actual BTRFS partition)
    mount -o subvolid=0 /dev/nvme0n1p7 /mnt/btrfs-root

    # Create subvolumes
    btrfs subvolume create /mnt/btrfs-root/@
    btrfs subvolume create /mnt/btrfs-root/@home
    btrfs subvolume create /mnt/btrfs-root/@nix

    # Copy data to subvolumes. The rsync command is safer than cp for this purpose.
    # Exclude temporary and special filesystems, and the destination itself.
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run /home/ /mnt/btrfs-root/@home/
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run /nix/ /mnt/btrfs-root/@nix/
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run / /mnt/btrfs-root/@/

    # Update configuration.nix to use the new subvolumes
    nano /etc/nixos/configuration.nix
    ```

    Add or modify the `fileSystems` block in `configuration.nix` to point to the new subvolumes (replace `/dev/nvme0n1p7` with your actual BTRFS partition):

    ```nix
    fileSystems = {
      "/" = {
        device = "/dev/nvme0n1p7";
        fsType = "btrfs";
        options = [ "subvol=@" "compress=zstd" "noatime" ];
      };
      "/home" = {
        device = "/dev/nvme0n1p7";
        fsType = "btrfs";
        options = [ "subvol=@home" "compress=zstd" "noatime" ];
      };
      "/nix" = {
        device = "/dev/nvme0n1p7";
        fsType = "btrfs";
        options = [ "subvol=@nix" "compress=zstd" "noatime" ];
      };
    };
    ```

    Rebuild and switch to the new configuration:

    ```bash
    nixos-rebuild switch
    ```

3.  Reboot to ensure the system uses the new BTRFS subvolume structure correctly.

4.  Proceed to Step 2 (Clone Dotfiles Repository).

### Option B: Manual Installation

This method gives you full control over partitioning and BTRFS subvolume creation from the start.

1.  Boot from NixOS installation media.

2.  Check the current partition layout to identify existing partitions and their device paths. Note that partition numbers (e.g., `nvme0n1p1`, `nvme0n1p7`) are examples and may vary on your system.

    ```bash
    lsblk -f
    ```

    Example output:

    ```
    NAME        FSTYPE LABEL   UUID                                 MOUNTPOINT
    nvme0n1
    ├─nvme0n1p1 vfat   SYSTEM  1234-ABCD                            /mnt/boot/efi
    ├─nvme0n1p3 ntfs   OS      5678-EFGH
    └─nvme0n1p7 btrfs          9abc-1234
    ```

3.  **Preserve** Windows partitions (if dual-booting):

    - **Do NOT** format or delete `nvme0n1p1` through `nvme0n1p5`.
    - `nvme0n1p1` is the shared EFI partition.

4.  Delete existing Linux partitions (e.g., `nvme0n1p6` and `nvme0n1p7` if they were Fedora partitions) to free up space. You can use `fdisk`, `cfdisk`, or `gparted`.

    ```bash
    fdisk /dev/nvme0n1  # Use 'd' to delete partitions
    # Or use cfdisk or gparted for a more user-friendly interface
    ```

5.  Create new NixOS partitions in the freed space. Use `fdisk`, `cfdisk`, or `gparted`.

    ```bash
    fdisk /dev/nvme0n1  # Use 'n' to create new partitions
    # Or use cfdisk or gparted
    ```

    - A `/boot` partition (if desired, \~512MB, ext4 filesystem type).
    - A **swap partition** (recommended: 32GB for the H7606WI’s 32GB RAM).
    - A root partition (`/`) using the remaining space.

6.  Format new NixOS partitions:

    ```bash
    mkfs.ext4 /dev/nvme0n1p6     # Example: Your new /boot partition (if created)
    # Recommended: Use BTRFS for root
    mkfs.btrfs /dev/nvme0n1p7     # Example: Your new root partition
    # OR use ext4
    # mkfs.ext4 /dev/nvme0n1p7
    ```

7.  Mount partitions.

    **For ext4**:

    ```bash
    mount /dev/nvme0n1p7 /mnt
    mkdir -p /mnt/boot
    mount /dev/nvme0n1p6 /mnt/boot
    mkdir -p /mnt/boot/efi
    mount /dev/nvme0n1p1 /mnt/boot/efi  # Do NOT format this existing EFI partition!
    ```

    **For BTRFS with subvolumes**: This is the recommended approach for BTRFS.

    ```bash
    # Mount the raw BTRFS partition
    mount /dev/nvme0n1p7 /mnt

    # Create desired subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@nix

    # Unmount the raw partition
    umount /mnt

    # Mount the main root subvolume
    mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt

    # Create mount points for other subvolumes
    mkdir -p /mnt/{home,nix,boot}

    # Mount other subvolumes
    mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
    mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix

    # Mount the separate /boot partition (if created)
    mount /dev/nvme0n1p6 /mnt/boot

    # Mount the existing EFI partition
    mkdir -p /mnt/boot/efi
    mount /dev/nvme0n1p1 /mnt/boot/efi  # Do NOT format!
    ```

8.  Generate initial NixOS configuration files based on the mounted partitions:

    ```bash
    nixos-generate-config --root /mnt
    ```

## Step 2: Clone Dotfiles Repository

This guide uses a dotfiles repository to manage your NixOS configuration and home-manager settings. This allows for reproducible and version-controlled system setup.

1.  Install Git (if not already present in the live environment):

    ```bash
    nix-env -iA nixos.git
    ```

2.  Clone the repository:

    ```bash
    cd ~
    mkdir -p source
    cd source
    git clone https://github.com/thebrianbug/dotfiles.git
    cd dotfiles
    ```

## Step 3: Create ASUS-Specific Configuration

1.  Create a host-specific directory for your ASUS laptop's configuration:

    ```bash
    mkdir -p hosts/asus-linux
    ```

2.  Copy the generated `hardware-configuration.nix` and `configuration.nix` into your new host directory. These files were created by `nixos-generate-config` and serve as the base for your system's hardware detection and initial settings.

    ```bash
    cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/asus-linux/
    cp /mnt/etc/nixos/configuration.nix ./hosts/asus-linux/
    ```

3.  Edit the main `configuration.nix` file within your dotfiles for ASUS-specific settings:

    ```bash
    nano hosts/asus-linux/configuration.nix
    ```

4.  Add the following ASUS-specific settings to `hosts/asus-linux/configuration.nix` (ensure you merge these with any existing content, don't just paste over everything):

    ```nix
    # Use kernel 6.15.4 (or later) for best ASUS hardware support for this model
    # NixOS 25.05 defaults to kernel 6.12, but 6.15.4 or later is recommended
    # for newer AMD CPUs and NVIDIA GPUs.
    boot.kernelPackages = pkgs.linuxPackages_latest; # This will pull the latest stable kernel available in Nixpkgs
    # If you specifically want 6.15.4 and it's not 'latest', you might need:
    # boot.kernelPackages = pkgs.linuxPackages_6_15; # (or whatever is the exact package name for 6.15)


    # ASUS-specific services for fan control, keyboard lighting, etc.
    services = {
      supergfxd.enable = true; # For GPU mode switching
      asusd = { # For asusctl features
        enable = true;
        enableUserService = true;
      };
    };

    # Fix for supergfxctl (ensures pciutils is in its path)
    systemd.services.supergfxd.path = [ pkgs.pciutils ];

    # NVIDIA configuration for RTX 4070
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable; # Use stable NVIDIA drivers
    };

    # WiFi and firmware for MediaTek MT7922 and other devices
    hardware.enableAllFirmware = true;
    hardware.firmware = [ pkgs.linux-firmware ]; # Essential for many devices, including WiFi
    boot.kernelModules = [ "mt7921e" "mt7922e" "i2c_hid_acpi" ]; # Load specific modules for WiFi and I2C HID devices

    # Power management daemons
    services.power-profiles-daemon.enable = true;
    services.tlp.enable = lib.mkDefault true; # For advanced power saving

    # Touchpad and touchscreen support
    services.libinput.enable = true; # Essential for touchpad
    hardware.sensor.iio.enable = lib.mkDefault true; # For IIO devices like touchscreens

    # Audio configuration using PipeWire (recommended over PulseAudio)
    sound.enable = true;
    hardware.pulseaudio.enable = false; # Disable PulseAudio if PipeWire is used
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true; # For PulseAudio compatibility layer
    };

    # GNOME 48 features, including HDR support
    services.xserver.desktopManager.gnome.enable = true;
    # Ensure Wayland is enabled for full HDR support with GNOME 48
    services.xserver.displayManager.gdm.wayland = true;
    ```

## ASUS Hardware Management

### Graphics Switching

Manage GPU configuration with `supergfxctl`. A logout or reboot is typically required after changing modes. Check the latest `supergfxctl` version (`supergfxctl --version`) at [asus-linux.org](https://asus-linux.org/).

```bash
# Check current graphics mode
supergfxctl -g

# List available modes
supergfxctl -m

# Set graphics mode (replace MODE with desired setting)
supergfxctl -m MODE

# Examples:
supergfxctl -m integrated  # Power-saving (AMD iGPU only)
supergfxctl -m hybrid     # Uses both GPUs, NVIDIA on-demand (Optimus)
supergfxctl -m dedicated  # Maximum performance (NVIDIA RTX 4070 dGPU)
```

### Keyboard Lighting

Manage the H7606WI’s RGB keyboard with `asusctl`:

```bash
# Set brightness (0-3: off, low, med, high)
asusctl -k low|med|high|off

# Set RGB mode
asusctl led-mode static      # Single color
asusctl led-mode breathe     # Breathing effect
asusctl led-mode rainbow     # Rainbow effect
# Per-key RGB example: (consult asusctl docs for specific key names/syntax)
asusctl led-mode aura --key red,green,blue
# List available modes
asusctl led-mode --help
```

### Power Profiles

Manage power profiles for performance or battery life using `asusctl`:

```bash
# Show current profile
asusctl profile -p

# List available profiles
asusctl profile -l

# Set profile
asusctl profile -P quiet|balanced|performance
```

**Note**: Full hibernation may be unreliable due to H7606WI firmware limitations (e.g., UEFI or GPU driver issues). If `systemctl hibernate` fails, check `dmesg` for errors and verify swap size (32GB recommended for 32GB RAM). As a fallback, configure `suspend-then-hibernate` or prioritize suspend-to-idle for quick power saving:

```nix
services.logind.lidSwitch = "suspend-then-hibernate"; # Tries suspend, then hibernates on low battery
services.logind.lidSwitchExternalPower = "suspend";
```

Add this kernel parameter for better suspend support on AMD systems:

```nix
boot.kernelParams = [ "amd_pstate=active" ];
```

Test suspend: `systemctl suspend`

### Performance Optimization

Optimize the H7606WI for creative workloads (e.g., 4K video editing, 3D rendering):

- **CPU Frequency Scaling**: Ensure `cpupower` is available and set the performance governor.

  ```nix
  environment.systemPackages = with pkgs; [ cpupower ];
  powerManagement.powertop.enable = true; # For general power optimization
  ```

  Set the performance governor (can be done manually or via systemd service):

  ```bash
  sudo cpupower frequency-set -g performance
  ```

- **NVIDIA Settings**: Install `nvidia-settings` for fan control or overclocking (launches a GUI tool).

  ```nix
  environment.systemPackages = with pkgs; [ nvidia-settings ];
  ```

  Run: `nvidia-settings` for GUI adjustments.

- **Verify Performance**: Check CPU/GPU usage:

  ```bash
  htop
  nvidia-smi
  ```

### HDR Support

The H7606WI’s 4K OLED supports HDR. **NixOS 25.05 with GNOME 48 introduces improved HDR support.** Ensure you're on a recent kernel (6.12+ for 25.05, or your tested 6.15.4) and NVIDIA driver for best support.

```nix
# Included in Step 3 already, but repeated for context:
environment.systemPackages = with pkgs; [ gnome.gnome-control-center ]; # If using GNOME
hardware.nvidia.modesetting.enable = true;
services.xserver.desktopManager.gnome.enable = true;
services.xserver.displayManager.gdm.wayland = true; # Ensure Wayland is enabled
```

Test HDR with an HDR-capable video:

```bash
mpv --vo=gpu --gpu-context=wayland --hdr-compute-peak=yes <hdr-video.mp4>
```

If HDR fails, verify your kernel and NVIDIA driver versions (`uname -r`, `nvidia-smi`). If Wayland HDR remains problematic, a fallback to X11 might be necessary:

```nix
services.xserver.enable = true;
services.xserver.displayManager.gdm.wayland = false; # Or other display manager settings
```

### Audio Configuration

The H7606WI’s audio (e.g., Realtek ALC codec) works well with `pipewire`.

```nix
sound.enable = true;
hardware.pulseaudio.enable = false; # Disable PulseAudio if PipeWire is used
services.pipewire = {
  enable = true;
  alsa.enable = true; # ALSA compatibility
  pulse.enable = true; # PulseAudio compatibility
};
```

Test audio:

```bash
speaker-test -c 2
```

For microphone issues, check detected devices:

```bash
arecord -l
```

Adjust levels with `alsamixer` if needed.

### Fan Control

Customize fan curves with `asusctl` for CPU and GPU independently or set a general mode:

```bash
asusctl fan-curve -m balanced # Set a balanced fan curve for both
asusctl fan-curve -e cpu -f balanced # Set balanced fan curve for CPU only
asusctl fan-curve -e gpu -f balanced # Set balanced fan curve for GPU only
```

List available fan modes: `asusctl fan-curve --help`.

Monitor temperatures:

```bash
sensors
```

### Known Limitations

- If the keyboard backlight fails, try explicitly setting a mode: `asusctl led-mode static`.
- Older ROG models (2020) may have NVIDIA GPU low-power issues; the H7606WI is largely unaffected with recent kernels.
- Use integrated graphics for optimal battery life when not gaming or rendering.
- Switching from NVIDIA to AMD graphics typically requires a logout or reboot.

### Wayland Support

Wayland (e.g., GNOME, Sway) is increasingly stable for NVIDIA GPUs in 2025, enhancing the H7606WI’s 4K OLED display scaling and HDR.

```nix
programs.sway.enable = true; # Or GNOME with Wayland enabled
hardware.nvidia.modesetting.enable = true;
```

Test with `supergfxctl -m hybrid`. If USB-C displays fail or other issues arise, fall back to X11 by disabling Wayland in your display manager.

```nix
services.xserver.enable = true;
services.xserver.displayManager.gdm.wayland = false; # Example for GDM
```

### Desktop Environment Integration

For GNOME, add these extensions for better hardware control integration:

```nix
environment.systemPackages = with pkgs; [
  gnomeExtensions.supergfxctl-gex      # GPU mode indicator
  gnomeExtensions.power-profile-switcher # Power profile controls
];
```

### Additional Configuration

#### Re-enabling Secure Boot (Optional)

Re-enabling Secure Boot is an advanced procedure. Proceed with caution and ensure you have a NixOS live USB for recovery.

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.loader.secureBoot = {
  enable = true;
  keyFile = "/path/to/secure-boot-key"; # Path to your generated Secure Boot key
  certFile = "/path/to/secure-boot-cert"; # Path to your generated Secure Boot certificate
};
```

**Steps**:

1.  Install `sbctl`:

    ```nix
    environment.systemPackages = with pkgs; [ sbctl ];
    ```

2.  After rebuilding and booting, generate and enroll keys:

    ```bash
    sudo sbctl create-keys
    sudo sbctl enroll-keys
    ```

3.  Rebuild your NixOS system: `sudo nixos-rebuild switch`

4.  Verify Secure Boot status in your UEFI settings (DEL key during boot).

**Warning**: Keep a NixOS live USB for recovery if boot fails. Back up your Secure Boot keys and certificates (`/path/to/secure-boot-key` and `/path/to/secure-boot-cert`).

**Recovery**: If Secure Boot prevents your system from booting:

1.  Boot from your NixOS live USB.
2.  Disable Secure Boot in UEFI (DEL key, Security → Secure Boot Control → Disable).
3.  If needed, reset existing keys: `sudo sbctl reset`.
4.  Rebuild your NixOS system: `sudo nixos-rebuild switch`.

#### Hide Unnecessary Boot Messages

Hide the "Nvidia kernel module not found" message if it appears:

```nix
systemd.services.nvidia-fallback.enable = false;
```

### Troubleshooting

#### Display Issues

1.  **External Displays**:

    - Ensure GPU mode is set to `dedicated` for consistent external display output via the NVIDIA GPU: `supergfxctl -m dedicated`.
    - Use X11 if Wayland encounters issues with external displays.

2.  **Black Screen After Login**:

    - Switch to a TTY (Ctrl+Alt+F3).
    - Check the current graphics mode: `supergfxctl -g`.
    - Try switching to integrated graphics: `supergfxctl -m integrated`.

3.  **Screen Brightness**:

    - Ensure you are using the latest kernel (`boot.kernelPackages = pkgs.linuxPackages_latest;`).
    - Add this kernel parameter for better ACPI support on some laptops:

    <!-- end list -->

    ```nix
    boot.kernelParams = [ "acpi_osi=Linux" ];
    ```

#### Power Management Issues

1.  **Poor Battery Life**:

    - Always use `integrated` mode when not performing GPU-intensive tasks.
    - Ensure power management services are enabled:

    <!-- end list -->

    ```nix
    services.power-profiles-daemon.enable = true;
    services.tlp.enable = true;
    ```

#### Touchpad/Touchscreen Issues

- **Touchpad**: Ensure `services.libinput.enable = true`. Test input:

  ```bash
  xinput list
  xinput test <id> # Replace <id> with your touchpad ID from xinput list
  ```

- **Touchscreen**: The H7606WI’s 4K OLED touchscreen supports stylus input (e.g., ASUS Pen 2.0). Ensure IIO support is enabled:

  ```nix
  hardware.sensor.iio.enable = true;
  ```

  Verify device detection:

  ```bash
  libinput list-devices
  ```

##### Touchscreen Calibration

For the H7606WI’s 4K OLED touchscreen, calibrate if input is inaccurate:

- **X11**: Install `xinput_calibrator`:

  ```nix
  environment.systemPackages = with pkgs; [ xinput_calibrator ];
  ```

  Run: `xinput_calibrator` and follow prompts.

- **Wayland**: Use desktop environment settings (e.g., GNOME Settings → Devices → Touchscreen).

For ASUS Pen 2.0, verify pressure sensitivity and tilt in applications like Xournal++ or Krita. If unsupported, install `wacomtablet` (which often includes drivers for non-Wacom pens that use similar protocols):

```nix
environment.systemPackages = with pkgs; [ wacomtablet ];
```

Configure via `wacomtablet` GUI or check kernel support:

```bash
lsmod | grep wacom
```

If issues occur, check kernel logs:

```bash
dmesg | grep -i input
```

Ensure the `i2c_hid_acpi` module is loaded in your `configuration.nix` (already included in Step 3):

```nix
boot.kernelModules = [ "i2c_hid_acpi" ];
```

## Networking Configuration

### WiFi Setup

The H7606WI’s MediaTek MT7922 WiFi card works out of the box with **NixOS 25.05** due to its modern kernel (6.12 by default, or your tested 6.15.4). Try the default NetworkManager setup first:

1.  **Basic NetworkManager Setup**:

    ```nix
    networking.networkmanager.enable = true;
    ```

2.  Test WiFi connectivity:

    ```bash
    nmcli device wifi list
    ```

3.  If WiFi fails, identify your network hardware:

    ```bash
    lspci | grep -i network
    ```

    Example output:

    ```
    00:14.3 Network controller: MediaTek Inc. MT7922 802.11ax PCI Express Wireless Network Adapter
    ```

4.  Troubleshooting (if needed for MediaTek MT7922):

    ```nix
    hardware.enableAllFirmware = true; # Ensures all firmware is available
    hardware.firmware = [ pkgs.linux-firmware ]; # Specifically for kernel firmware blobs
    boot.kernelModules = [ "mt7921e" "mt7922e" ]; # Explicitly load MediaTek modules
    networking.networkmanager.wifi.powersave = false; # May improve stability for some WiFi chips
    ```

#### WiFi 6E/7 Support

The H7606WI’s MT7922 supports WiFi 6E/7. You should generally not need specific kernel parameters for this chip. Verify performance and connection details:

```bash
iw dev wlan0 link # Check link speed and details
iperf3 -c <server> # Test throughput to a local server
```

Check for MT7922 firmware updates via `fwupd`:

```bash
sudo fwupdmgr refresh
sudo fwupdmgr update
```

5.  **Temporary Internet**: If WiFi is problematic during installation, use USB tethering from a phone or an Ethernet adapter for a temporary connection.

### Bluetooth Configuration

Enable Bluetooth services and ensure they start on boot:

```nix
services.blueman.enable = true; # A graphical Bluetooth manager
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;
```

## Verification and Testing

### Hardware Checklist

After installation, verify that all essential hardware components are working:

- Graphics switching: `supergfxctl -g`
- Power profiles: `asusctl profile -p`
- Keyboard backlight: `asusctl -k high`
- WiFi: Connect to a network and browse.
- Bluetooth: Pair a device (e.g., headphones, mouse).
- Function keys: Test volume, brightness, and lighting keys.
- Suspend/Resume: Test with `systemctl suspend`.
- Touchscreen/Stylus: Test in an application like Xournal++ or Krita.
- Audio: Test with `speaker-test -c 2`.
- HDR: Test with `mpv` and an HDR video.

### Quick Diagnostics

Use these commands for quick system health checks:

```bash
systemctl status asusd supergfxd # Check status of ASUS services
lsmod | grep -E 'nvidia|amdgpu' # Verify GPU drivers are loaded
dmesg | grep -i -E 'error|fail' # Check kernel logs for errors
glxinfo | grep "OpenGL renderer" # Verify correct GPU is in use (for X11)
```

## Firmware Updates

### ASUS BIOS Updates

Download BIOS updates from [ASUS Support](https://www.asus.com/support/) for the ProArt P16 H7606WI. Save to a USB drive and follow ASUS’s BIOS update instructions. If dual-booting isn't available, or you prefer not to boot into Windows, use the Windows USB method described below.

### Using fwupd in NixOS

`fwupd` allows updating firmware for supported devices directly from Linux, often via the Linux Vendor Firmware Service (LVFS).

```nix
services.fwupd.enable = true;
```

Manage updates:

```bash
systemctl status fwupd # Check fwupd service status
fwupdmgr get-devices # List detected devices
sudo fwupdmgr refresh # Check for new updates
sudo fwupdmgr get-updates # See available updates
sudo fwupdmgr update # Apply updates
```

**Note**: The H7606WI’s firmware is generally well-supported by LVFS. If `fwupd` fails or specific components (e.g., TPM, EC) aren’t supported, check LVFS compatibility at [fwupd.org](https://fwupd.org). In such cases, fall back to Windows-based USB updates with files from [ASUS Support](https://www.asus.com/us/Laptops/ASUS-ProArt-P16-H7606WI/HelpDesk_BIOS/).

### Creating a Windows USB for Firmware Updates

For BIOS updates when `fwupd` is not an option or if a full Windows installation is not available:

1.  Create a Windows installation USB drive.
2.  Boot into the Windows setup environment.
3.  Press Shift+F10 to open a Command Prompt.
4.  From the Command Prompt, you can navigate to a separate USB drive containing the BIOS update files downloaded from ASUS Support and run the update utility.

**Note**: The H7606WI’s hardware is well-supported in recent kernels (6.12+ in NixOS 25.05, or your tested 6.15.4), reducing the frequency of critical firmware updates.

## Step 4: Update Flake Configuration

Now that your NixOS configuration files are in your dotfiles repository, you need to tell your `flake.nix` how to build your specific ASUS system.

1.  Edit your `flake.nix` file (located in the root of your dotfiles repository):

    ```bash
    nano flake.nix
    ```

2.  Add the following `asus-linux` configuration to the `nixosConfigurations` attribute set within your `flake.nix`. This defines how your system is built, including pulling in your host-specific configuration and enabling Home Manager for your user.

    ```nix
    # ... (rest of your flake.nix) ...

    nixosConfigurations = {
      asus-linux = nixpkgs.lib.nixosSystem {
        inherit system; # Inherits the system architecture (e.g., "x86_64-linux")
        modules = [
          # Import your host-specific configuration
          ./hosts/asus-linux/configuration.nix
          # Enable and configure Home Manager for your user
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.brianbug = import ./home-manager/nixos; # Adjust 'brianbug' to your username
          }
        ];
      };
      # ... (other configurations if you have them) ...
    };

    # ... (rest of your flake.nix) ...
    ```

## Step 5: Install NixOS with Your Configuration

### If Using Calamares

If you used the Calamares installer, you have already completed the base installation. Proceed to Step 2 (Clone Dotfiles Repository) and follow the subsequent steps to apply your dotfiles configuration.

### If Using Manual Installation

For manual installations, execute the `nixos-install` command, pointing it to your new flake configuration. Ensure you are in the root directory of your `dotfiles` repository.

1.  Install NixOS:

    ```bash
    nixos-install --flake .#asus-linux
    ```

    If `nixos-install` fails, use `nix flake check` to diagnose potential issues:

    ```bash
    nix flake check
    ```

    Common errors include:

    - Missing dependencies: Ensure `flake.nix` includes `home-manager` and any other required inputs.
    - Syntax errors: Validate your `configuration.nix` and `flake.nix` files using `nix fmt` (a Nix formatter).

2.  Set the root password when prompted during the installation process.

3.  Reboot your system:

    ```bash
    reboot
    ```

## Step 6: Post-Installation

After logging into your newly installed NixOS system:

1.  Log in with your user account.

2.  Verify that the ASUS-specific services are running correctly:

    ```bash
    systemctl status asusd
    systemctl status supergfxd
    ```

3.  Check your current graphics mode:

    ```bash
    supergfxctl -g
    ```

4.  Keep your configuration updated. Navigate to your dotfiles directory, pull any new changes, and rebuild your system:

    ```bash
    cd ~/source/dotfiles
    git pull
    sudo nixos-rebuild switch --flake .#asus-linux
    ```

5.  For system updates with BTRFS, it's a good practice to create a snapshot before rebuilding:

    ```bash
    sudo btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d)
    sudo nixos-rebuild switch --flake .#asus-linux
    ```

## Dual-Boot Considerations

For successful dual-booting with Windows:

1.  The bootloader (GRUB or systemd-boot) should automatically detect your Windows installation.

2.  If Windows does not appear in the boot menu, ensure your `bootloader` configuration in `configuration.nix` allows for detection. For `systemd-boot`, these are typical settings:

    ```nix
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10; # Keep more boot entries
    ```

3.  Enable NTFS filesystem support in NixOS to read and write to Windows partitions (if needed):

    ```nix
    boot.supportedFilesystems = [ "ntfs" ];
    ```

## Troubleshooting (Advanced)

### NVIDIA Driver Configuration

Confirm your NVIDIA configuration (as included in Step 3):

```nix
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};
```

### Supergfxctl Issues

If `supergfxctl -g` (or other `supergfxctl` commands) fails, ensure `pciutils` is correctly in its path:

```nix
systemd.services.supergfxd.path = [ pkgs.pciutils ];
```

### Graphics Switching (Recap)

```bash
supergfxctl -m integrated
supergfxctl -m hybrid
supergfxctl -m dedicated
```

### ROG Control Center (`asusd-user`)

If the `asusctl` user service is not working (e.g., keyboard lighting issues for your user), check its status:

```bash
systemctl --user status asusd-user
```

## BTRFS Configuration (Recap)

Recommended BTRFS subvolume layout for better snapshot management and system resilience:

```nix
fileSystems = {
  "/" = {
    device = "/dev/nvme0n1p7"; # Your BTRFS root partition
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };
  "/home" = {
    device = "/dev/nvme0n1p7"; # Same partition
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };
  "/nix" = {
    device = "/dev/nvme0n1p7"; # Same partition
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };
};
```

### Swap Configuration (Recap)

**Option A: Swap Partition (Recommended)**

```bash
mkswap /dev/nvme0n1p8 # Format your swap partition
swapon /dev/nvme0n1p8 # Enable it immediately
```

**Option B: Swap File (on BTRFS)**

```bash
# Create a dedicated subvolume for swap if you plan to use a swapfile on BTRFS
btrfs subvolume create /swap
# Disable copy-on-write for the swapfile to prevent instability
chattr +C /swap/swapfile # Run this *before* creating the file
dd if=/dev/zero of=/swap/swapfile bs=1M count=32768 # Create a 32GB swapfile
chmod 600 /swap/swapfile # Set correct permissions
mkswap /swap/swapfile # Format the swapfile
swapon /swap/swapfile # Enable the swapfile
```

Add your swap device to `configuration.nix`:

```nix
swapDevices = [
  { device = "/dev/nvme0n1p8"; } # For swap partition
  # Or for a swap file:
  # { device = "/swap/swapfile"; }
];
```

### BTRFS Snapshot Configuration (`btrbk`)

Example configuration for `btrbk` to manage BTRFS snapshots:

```nix
environment.etc."btrbk/btrbk.conf".text = ''
  snapshot_dir /.snapshots
  snapshot_preserve_min 7d
  snapshot_preserve 30d
  volume /
    subvolume @
    subvolume @home
    subvolume @nix
'';
```

### BTRFS Maintenance

Automate BTRFS scrubbing (checksum verification) with a systemd timer:

```nix
systemd.services.btrfs-scrub = {
  description = "BTRFS scrub";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub start -B /";
  };
};

systemd.timers.btrfs-scrub = {
  description = "Monthly BTRFS scrub";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "monthly";
    Persistent = true;
  };
};
```

Perform manual maintenance operations:

```bash
sudo btrfs filesystem usage /       # Check BTRFS space usage
sudo btrfs balance start -dusage=85 / # Rebalance data if disk usage is uneven (can take a long time)
sudo btrfs scrub start /            # Manually start a scrub
sudo btrfs scrub status /           # Check scrub progress
```

## Time Synchronization for Dual-Boot

To prevent time discrepancies when dual-booting Windows and NixOS, configure your hardware clock to use local time (which Windows typically defaults to).

```nix
time.hardwareClockInLocalTime = true;
```

Alternatively, you can configure Windows to use UTC (recommended if you primarily use Linux):

1.  Open `regedit` in Windows.
2.  Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`.
3.  Create a new `DWORD (32-bit) Value` named `RealTimeIsUniversal` and set its value to `1`.

## Backup Strategy

NixOS generations provide built-in system configuration rollback. For data, implement dedicated backup solutions.

1.  **System Configuration**: Managed by NixOS generations.
2.  **Data Snapshots**: Use `btrbk` (as configured above) or `snapper` for local BTRFS snapshots.
3.  **Offsite Backups**: Consider tools like `restic`, `borgbackup`, or `rclone` for encrypted, offsite backups of your important data.

To enable `btrbk` as a daily snapshot service:

```nix
environment.systemPackages = with pkgs; [ btrbk ];
systemd.services.btrbk = {
  description = "BTRBK periodic snapshot";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.btrbk}/bin/btrbk run";
  };
};
systemd.timers.btrbk = {
  description = "Daily BTRBK snapshots";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

## System Recovery

### Method 1: Standard Recovery (Chroot)

If your system fails to boot, you can chroot into your NixOS installation from a live USB to troubleshoot and rebuild.

1.  Boot from your NixOS installation media.

2.  Mount your BTRFS subvolumes (adjust device paths as necessary):

    ```bash
    mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt
    mkdir -p /mnt/{home,nix,boot/efi}
    mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
    mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix
    mount /dev/nvme0n1p1 /mnt/boot/efi
    ```

3.  Chroot into your installed system:

    ```bash
    nixos-enter
    ```

    From here, you can edit `configuration.nix` and run `nixos-rebuild switch` (using `--flake .#asus-linux` if your configuration is flake-based and you copied your dotfiles into the chroot's source directory).

### Method 2: Snapshot Recovery

If you have BTRFS snapshots, you can recover files or even revert your root filesystem to a previous state.

1.  Boot from installation media.
2.  Mount your BTRFS root partition (the one containing your subvolumes): `mount /dev/nvme0n1p7 /mnt`
3.  Mount a specific snapshot (replace `123/snapshot` with the path to your desired snapshot, e.g., from `/.snapshots`): `mount -o subvol=.snapshots/123/snapshot /dev/nvme0n1p7 /recovery`
4.  Copy needed files from `/recovery` back to your main system (`/mnt`) or promote the snapshot.

### Method 3: Rollback to Previous Generation

NixOS automatically keeps previous system configurations (generations). If a system update causes issues, you can easily roll back.

1.  At the bootloader (systemd-boot), select an older NixOS generation from the menu.

2.  Once booted into the stable previous generation, you can then attempt to fix your `configuration.nix` or simply revert to that generation permanently:

    ```bash
    sudo nixos-rebuild switch --rollback
    ```

## Glossary

- **BTRFS Subvolume**: A flexible feature of the BTRFS filesystem that allows for creating isolated, named filesystem trees within a single BTRFS volume. Useful for snapshots and organizing data.
- **Chroot**: A command-line utility used to change the apparent root directory for the current running process and its children. Essential for recovery and troubleshooting.
- **Flake**: A modern Nix feature that provides a reproducible and declarative way to define NixOS configurations, development environments, and packages, making them easier to share and manage.
- **LUKS2**: Linux Unified Key Setup, version 2. A standard for disk encryption in Linux, providing robust full-disk encryption.
- **TPM**: Trusted Platform Module. A secure cryptoprocessor (hardware chip) designed to secure hardware by integrating cryptographic keys into devices. Used here for automatic LUKS unlocking.

## Tested Features

- **Validated**: GPU switching (integrated, hybrid, dedicated), RGB keyboard, WiFi (MT7922), Bluetooth, touchpad, touchscreen (basic input), power profiles, BTRFS snapshots, dual-boot, audio.
- **Tested (with NixOS 25.05 and Kernel 6.15.4)**: HDR on 4K OLED, ASUS Pen 2.0 pressure sensitivity/tilt.
- **Untested**: Hibernation. Test unverified features on your system and report any issues to the NixOS Discourse or ASUS Linux Community.

## References

- [NixOS Manual](https://nixos.org/manual/nixos/latest/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [ASUS-Linux NixOS Guide](https://asus-linux.org/guides/nixos)
- [Supergfxctl Documentation](https://gitlab.com/asus-linux/supergfxctl)
- [Asusctl Documentation](https://gitlab.com/asus-linux/asusctl)
- [NixOS Wiki on Laptops](https://nixos.wiki/wiki/Laptop)
- [NixOS Hardware Configuration Database](https://github.com/NixOS/nixos-hardware)
- [ASUS Linux Community](https://asus-linux.org/community)

## Notes

This configuration targets **NixOS 25.05 "Warbler"** and uses a recent kernel (6.12 by default, with instructions for **6.15.4**). For basic WiFi configuration, rely on NetworkManager via GUI. For H7606 series variants (e.g., different CPUs, GPUs, or WiFi chips), verify hardware with `lspci` and `lsusb`, and adjust `boot.kernelModules` or `hardware.firmware` as needed. Always check for newer kernel updates (e.g., 6.16+) and `supergfxd` versions for continued improvement.
