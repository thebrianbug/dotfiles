# NixOS Installation Guide: ASUS Linux Setup

This guide walks you through installing NixOS on an ASUS laptop with all necessary configurations from this dotfiles repository. It includes instructions for both manual installation and using the Calamares installer.

This guide has been specifically tested with the ASUS ProArt P16 model, but should work for most ASUS laptops including ROG series.

## Prerequisites

- NixOS installation media (latest version recommended)
- Internet connection
- Basic knowledge of NixOS and the command line

## Pre-Installation Steps

### Backup Proprietary eSupport Drivers

If you have Windows installed, back up the proprietary ASUS drivers before removing Windows partitions:

1. In Windows, copy the entire `C:\eSupport` folder to external storage
2. These drivers may be needed if you ever reinstall Windows or use Windows in a VM

### Disable Secure Boot

**IMPORTANT FOR DUAL BOOT USERS:** Disable Windows BitLocker before doing this or your data will be inaccessible!

1. Press DEL repeatedly during boot to enter UEFI setup
2. Press F7 for advanced mode
3. Security → Secure Boot Control → Disable
4. Save and exit

### Use the Laptop Screen

During installation, disconnect external displays to avoid unpredictable behavior with graphics switching.

### Switch to Hybrid Mode on Windows (2022+ Models)

For 2022 or newer ASUS models, switch to Hybrid graphics mode in Windows before installing NixOS to prevent potential issues.

## Partition Overview

Before beginning installation, here's a breakdown of disk partitions and what to keep if dual-booting with Windows:

| Partition   | Filesystem | Label    | Type                         | Purpose                              | Keep?                  |
| ----------- | ---------- | -------- | ---------------------------- | ------------------------------------ | ---------------------- |
| `nvme0n1p1` | vfat       | SYSTEM   | EFI System Partition         | Bootloader (shared Fedora + Windows) | ✅ Yes                 |
| `nvme0n1p2` | _(none)_   | _(none)_ | Microsoft Reserved Partition | Required for Windows (no FS)         | ✅ Yes                 |
| `nvme0n1p3` | ntfs       | OS       | Windows System               | Main Windows installation            | ✅ Yes                 |
| `nvme0n1p4` | ntfs       | RECOVERY | Windows Recovery Environment | Recovery tools/partition             | ✅ Yes (for dual-boot) |
| `nvme0n1p5` | vfat       | MYASUS   | ASUS preinstalled tools      | Manufacturer apps/drivers            | ✅ Yes (for dual-boot) |

Any existing Linux partitions (like Fedora's `/boot` or root partitions) can be safely removed and replaced with NixOS partitions.

## Disk Encryption (Optional)

> **Note**: Skip this section if you don't need encryption. Proceed to standard installation.

This guide covers LUKS Full Disk Encryption, requiring a passphrase at boot time.

### Implementing Disk Encryption

#### With Calamares Installer

The Calamares installer offers an encryption checkbox during the partitioning step. Simply:

1. Check "Encrypt system" when creating the root partition
2. Set a strong encryption passphrase
3. The installer will handle the LUKS setup automatically

#### With Manual Installation

During the manual installation, after creating partitions but before formatting:

1. Set up LUKS encryption on your root partition:

   ```bash
   # Create encrypted partition - you\'ll be asked to set a passphrase
   cryptsetup luksFormat /dev/nvme0n1p7

   # Open the encrypted partition
   cryptsetup luksOpen /dev/nvme0n1p7 cryptroot
   ```

2. Format the opened LUKS device instead of the raw partition:

   ```bash
   # For BTRFS (recommended)
   mkfs.btrfs /dev/mapper/cryptroot
   # OR for ext4
   # mkfs.ext4 /dev/mapper/cryptroot
   ```

3. Mount the opened LUKS device:

   ```bash
   mount /dev/mapper/cryptroot /mnt
   ```

4. Add this to your `configuration.nix` after installation:

   ```nix
   boot.initrd.luks.devices = {
     "cryptroot" = {
       device = "/dev/disk/by-uuid/YOUR-UUID-HERE"; # Replace with actual UUID
       preLVM = true;
     };
   };
   ```

   To get the UUID of your encrypted partition:

   ```bash
   ls -la /dev/disk/by-uuid/
   ```

### Notes on Encryption and Dual-Boot

- Encryption is independent of the Windows BitLocker issue mentioned earlier
- You can encrypt your NixOS partitions regardless of whether Secure Boot is enabled or disabled
- For maximum security, consider encrypting both your Windows (using BitLocker) and NixOS partitions

## Step 1: Base NixOS Installation

### Option A: Using Calamares Installer (Graphical)

1. Boot from the NixOS installation media
2. Open the Calamares installer by clicking on the "Install System" icon
3. Follow the initial setup steps (language, location, keyboard)
4. When you reach the partitioning section:
   - Select **Manual partitioning** for control over existing partitions
   - **Do NOT format or delete** partitions `nvme0n1p1` through `nvme0n1p5` if you want to preserve Windows
   - Delete any existing Linux partitions (like Fedora's partitions)
   - Create the following NixOS partitions:
     - If needed, a new `/boot` partition (ext4, ~512MB)
     - A root partition (`/`) using the remaining space (**recommended: btrfs** or ext4)
     - **Important:** Calamares only formats partitions as BTRFS but **does not** create any subvolumes (a key limitation). You'll need to set these up manually after installation (see Post-Installation BTRFS Setup below)
   - Mount `nvme0n1p1` (the existing EFI partition) at `/boot/efi` but **do NOT format it**
5. Continue with the installer:
   - Create your user account
   - Set passwords
   - Review and confirm installation settings
6. Complete the installation and reboot

### Post-Installation BTRFS Setup (Calamares)

Since Calamares doesn't create any subvolumes when formatting with BTRFS, you'll need to set them up manually after installation to benefit from BTRFS features:

1. Boot into your new NixOS system
2. Create proper BTRFS subvolumes and move your data:

   ```bash
   # Login as root or use sudo for these commands
   sudo -i

   # Create a temporary mount point
   mkdir /mnt/btrfs-root

   # Mount the BTRFS partition (adjust device as needed)
   mount -o subvolid=0 /dev/nvme0n1p7 /mnt/btrfs-root

   # Create subvolumes
   btrfs subvolume create /mnt/btrfs-root/@
   btrfs subvolume create /mnt/btrfs-root/@home
   btrfs subvolume create /mnt/btrfs-root/@nix

   # Copy data to subvolumes (this will take some time)
   cp -a --reflink=auto /home/* /mnt/btrfs-root/@home/
   cp -a --reflink=auto /nix/* /mnt/btrfs-root/@nix/
   cp -a --reflink=auto --one-file-system /* /mnt/btrfs-root/@/

   # Update your configuration.nix to use these subvolumes
   nano /etc/nixos/configuration.nix
   ```

   Add the following to your configuration.nix:

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

   Then rebuild and switch to apply the changes:

   ```bash
   nixos-rebuild switch
   ```

   After rebooting, you'll be using your new BTRFS subvolume structure.

3. After setting up subvolumes, continue with Step 2 (Clone Dotfiles Repository)

### Option B: Manual Installation

1. Boot from NixOS installation media
2. Check your current partition layout:
   ```bash
   lsblk -f
   # or
   fdisk -l /dev/nvme0n1
   ```
3. **Preserve** essential Windows partitions (if dual-booting):
   - **DO NOT** format or delete partitions `nvme0n1p1` through `nvme0n1p5`
   - `nvme0n1p1` is your EFI partition that will be shared between Windows and NixOS
4. Delete any existing Linux partitions (like Fedora's `/boot` and root partitions):
   ```bash
   # For example, if p6 and p7 were Fedora partitions
   fdisk /dev/nvme0n1  # Then use 'd' command to delete partitions
   # Or use another tool like cfdisk or gparted
   ```
5. Create new NixOS partitions:
   ```bash
   # Example: Create a new boot partition (if needed) and root partition
   fdisk /dev/nvme0n1  # Then use 'n' command to create partitions
   # Or use another tool like cfdisk or gparted
   ```
6. Format only the new NixOS partitions (example assumes p6 for /boot, p7 for root):
   ```bash
   mkfs.ext4 /dev/nvme0n1p6      # Boot partition (if created)
   # Recommended: Use btrfs for root partition
   mkfs.btrfs /dev/nvme0n1p7      # Root partition
   # OR use ext4 if preferred
   # mkfs.ext4 /dev/nvme0n1p7
   ```
7. Mount the partitions:

   **For standard ext4 partitions:**

   ```bash
   mount /dev/nvme0n1p7 /mnt     # Root partition
   mkdir -p /mnt/boot
   mount /dev/nvme0n1p6 /mnt/boot # If you created a separate boot partition
   mkdir -p /mnt/boot/efi
   mount /dev/nvme0n1p1 /mnt/boot/efi # Mount existing EFI partition (DO NOT format!)
   ```

   **For BTRFS with subvolumes (recommended):**

   ```bash
   # After formatting with mkfs.btrfs
   mount /dev/nvme0n1p7 /mnt

   # Create subvolumes
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   btrfs subvolume create /mnt/@nix

   # Remount with subvolumes
   umount /mnt
   mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt
   mkdir -p /mnt/{home,nix,boot}
   mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
   mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix

   # Mount boot partitions
   mount /dev/nvme0n1p6 /mnt/boot # If you created a separate boot partition
   mkdir -p /mnt/boot/efi
   mount /dev/nvme0n1p1 /mnt/boot/efi # Mount existing EFI partition (DO NOT format!)
   ```

8. Generate initial configuration:
   ```bash
   nixos-generate-config --root /mnt
   ```

## Step 2: Clone Dotfiles Repository

1. Install Git:
   ```bash
   nix-env -iA nixos.git
   ```
2. Clone this repository:
   ```bash
   cd ~
   mkdir -p source
   cd source
   git clone https://github.com/thebrianbug/dotfiles.git
   cd dotfiles
   ```

## Step 3: Create ASUS-Specific Configuration

1. Create host directory:
   ```bash
   mkdir -p hosts/asus-linux
   ```
2. Copy both the hardware configuration and the installer-generated configuration.nix:
   ```bash
   cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/asus-linux/
   cp /mnt/etc/nixos/configuration.nix ./hosts/asus-linux/
   ```
3. Edit the configuration file:

   ```bash
   nano hosts/asus-linux/configuration.nix
   ```

4. Add these ASUS-specific settings to the generated configuration.nix:

   ```nix
   # Use latest kernel for best ASUS hardware support
   boot.kernelPackages = pkgs.linuxPackages_latest;

   # Add ASUS-specific services
   services = {
     supergfxd.enable = true;
     asusd = {
       enable = true;
       enableUserService = true;
     };
   };

   # Fix for supergfxctl
   systemd.services.supergfxd.path = [ pkgs.pciutils ];
   ```

## ASUS Hardware Management

### Graphics Switching

With the ASUS-specific services enabled, you can manage your GPU configuration using `supergfxctl`:

```bash
# Check current graphics mode
supergfxctl -g

# List available modes
supergfxctl -m

# Set graphics mode (integrated, hybrid, compute, vfio, or dedicated)
supergfxctl -m MODE

# Examples:
supergfxctl -m integrated  # Power-saving mode, uses AMD/Intel GPU only
supergfxctl -m hybrid      # Uses both GPUs, enabling Nvidia on-demand
supergfxctl -m dedicated   # Maximum performance, uses Nvidia GPU exclusively
```

Note: After changing graphics modes, a logout or reboot is typically required.

### Keyboard Lighting

Manage your keyboard lighting using `asusctl`:

```bash
# Set keyboard brightness level (0-3)
asusctl -k low|med|high|off

# Set keyboard RGB mode (if supported)
asusctl led-mode static     # Single color
asusctl led-mode breathe    # Breathing effect
asusctl led-mode rainbow    # Rainbow effect
```

### Power Profiles

Manage power profiles for better performance or battery life:

```bash
# Show current profile
asusctl profile -p

# List available profiles
asusctl profile -l

# Set profile
asusctl profile -P quiet|balanced|performance
```

### Known Limitations

- If keyboard backlight doesn't work automatically, set a mode with `asusctl led-mode static`
- On 2020 models of ROG laptops, the Nvidia GPU may have issues entering low-power state
- For optimal battery life, use integrated graphics mode when not gaming
- If the laptop has booted in Nvidia mode, switching to AMD integrated graphics requires a reboot or logout
- When using external displays via USB-C DisplayPort, you may need to use X11 instead of Wayland

### Desktop Environment Integration

If using GNOME with NixOS, add these useful extensions to your configuration:

```nix
environment.systemPackages = with pkgs; [
  gnomeExtensions.supergfxctl-gex  # GPU mode indicator
  gnomeExtensions.power-profile-switcher  # Power profile controls
];
```

### Additional Configuration

#### Re-enabling Secure Boot (Optional)

If your system is stable and you want to re-enable Secure Boot:

```nix
# Add to your configuration.nix
boot.bootloader.secureBoot.enable = true;
```

#### Hide Unnecessary Boot Messages

To hide the "Nvidia kernel module not found. Falling back to Nouveau" message when booting in integrated mode:

```nix
systemd.services.nvidia-fallback.enable = false;
```

### Troubleshooting

#### Display Issues

1. **External Displays**: If external displays aren't working:

   - Try setting the GPU mode to dedicated or hybrid: `supergfxctl -m dedicated`
   - For USB-C/DisplayPort connections, use X11 instead of Wayland

2. **Black Screen After Login**: This might be related to GPU mode switching

   - Switch to a TTY console (Ctrl+Alt+F3)
   - Run `supergfxctl -g` to check current mode
   - Try changing to a different mode: `supergfxctl -m integrated`

3. **Screen Brightness Control Not Working**:
   - Ensure you're using the latest kernel
   - Add `acpi_osi=Linux` to your boot parameters:
     ```nix
     boot.kernelParams = [ "acpi_osi=Linux" ];
     ```

#### Power Management Issues

1. **Poor Battery Life**:
   - Set graphics to integrated mode when not gaming
   - Enable power management services:
     ```nix
     services.power-profiles-daemon.enable = true;
     ```
   - Install TLP for advanced power management:
     ```nix
     services.tlp.enable = true;
     ```

## Networking Configuration

### WiFi Setup

Most modern ASUS laptops (including ProArt series) have WiFi that works out of the box with recent NixOS versions. Always try the default configuration first:

1. **Basic NetworkManager Setup**:

   ```nix
   networking.networkmanager.enable = true;
   ```

2. **First Test**: After installing NixOS, check if WiFi works with the default setup

   ```bash
   # List available wifi networks
   nmcli device wifi list
   ```

3. **Only If WiFi Doesn't Work**: Identify your hardware and apply specific fixes

   ```bash
   # Identify your WiFi adapter
   lspci | grep -i network
   ```

4. **Troubleshooting Options** (only if needed):

   For Intel WiFi (common in ASUS laptops):

   ```nix
   # These parameters help with problematic Intel AX cards
   boot.kernelParams = [
     "iwlwifi.disable_11ax=Y"  # Disable WiFi 6 which can cause issues
     "iwlmvm.power_scheme=1"   # Better power management
   ];
   ```

   For MediaTek cards (common in ProArt series):

   ```nix
   # Basic support for MediaTek cards
   hardware.enableAllFirmware = true;
   hardware.firmware = [ pkgs.linux-firmware ];

   # If experiencing poor performance or connection issues
   boot.kernelModules = [ "mt7921e" ]; # Adjust module name if using a different MediaTek chip
   networking.networkmanager.wifi.powersave = false; # Disable power saving for better stability
   ```

   > **Note for ProArt P16 Users**: The MediaTek cards in these laptops should work with basic configurations but may have performance limitations similar to Fedora.

5. **Temporary Internet During Setup**:
   - Use USB tethering from your phone if WiFi isn't working
   - Connect via Ethernet if available

### Bluetooth Configuration

```nix
# Enable bluetooth
services.blueman.enable = true;
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;
```

## Verification and Testing

### Hardware Checklist

- Graphics switching: `supergfxctl -g` (should show current mode)
- Power profiles: `asusctl profile -p` (should list available profiles)
- Keyboard backlight: `asusctl -k high` (should change keyboard brightness)
- WiFi: Connect to your network
- Bluetooth: Pair a device if available
- Function keys: Test volume, brightness, and keyboard lighting keys
- Suspend/Resume: Close lid or use power menu to test sleep/wake

### Quick Diagnostics

```bash
systemctl status asusd supergfxd
lsmod | grep -E 'nvidia|amdgpu'
dmesg | grep -i -E 'error|fail'
glxinfo | grep "OpenGL renderer"
```

## Firmware Updates

### ASUS BIOS Updates

ASUS firmware updates should generally be performed within Windows. If you're dual-booting:

1. Boot into Windows
2. Use MyASUS application to check and apply firmware updates
3. Reboot back to NixOS

If you're not dual-booting, consider these options:

### Using fwupd in NixOS

Add to your configuration.nix:

```nix
services.fwupd.enable = true;
```

Then refresh and check for updates:

```bash
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update
```

### Creating a Windows USB

For major BIOS updates when fwupd doesn't work:

1. Create a Windows installation USB
2. Boot from the USB and enter the Windows setup
3. Open Command Prompt (Shift+F10)
4. Run the BIOS update from a USB drive containing the update files

> **Note**: ProArt P16 owners may need less frequent firmware updates as the hardware tends to be well-supported in recent kernels

## Step 4: Update Flake Configuration

1. Edit the flake.nix file:

   ```bash
   nano flake.nix
   ```

2. Add a new entry to `nixosConfigurations`:
   ```nix
   asus-linux = nixpkgs.lib.nixosSystem {
     inherit system;
     modules = [
       ./hosts/asus-linux/configuration.nix
       home-manager.nixosModules.home-manager {
         home-manager.useGlobalPkgs = true;
         home-manager.useUserPackages = true;
         home-manager.users.brianbug = import ./home-manager/nixos;
       }
     ];
   };
   ```

## Step 5: Install NixOS with Your Configuration

### If you used Calamares installer:

1. Boot into your newly installed NixOS system
2. Open a terminal and continue with Step 2 (Clone Dotfiles Repository)

### If you used manual installation:

1. Install NixOS with your configuration:

   ```bash
   nixos-install --flake .#asus-linux
   ```

2. Set a root password when prompted

3. Reboot:
   ```bash
   reboot
   ```

## Step 6: Post-Installation

1. Log in with your user account

2. Verify ASUS services are running:

   ```bash
   systemctl status asusd
   systemctl status supergfxd
   ```

3. Check graphics mode:

   ```bash
   supergfxctl -S
   ```

4. If you need to update your configuration in the future:

   ```bash
   cd ~/source/dotfiles
   git pull
   sudo nixos-rebuild switch --flake .#asus-linux
   ```

5. System updates with BTRFS:

   ```bash
   # Before major system updates, consider creating a BTRFS snapshot
   sudo btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d)

   # Then proceed with the update
   sudo nixos-rebuild switch --flake .#asus-linux
   ```

   This creates a read-only snapshot before updates that you can recover from if needed.

## Dual-Boot Considerations

If dual-booting with Windows:

1. The bootloader (GRUB or systemd-boot) should automatically detect Windows and add it to the boot menu
2. If Windows doesn't appear in the boot menu, check your NixOS configuration:
   ```nix
   boot.loader.systemd-boot.enable = true;  # Or GRUB
   boot.loader.efi.canTouchEfiVariables = true;
   boot.loader.systemd-boot.configurationLimit = 10;  # Limits number of generations
   ```
3. For accessing Windows files from NixOS, enable NTFS support:
   ```nix
   boot.supportedFilesystems = [ "ntfs" ];
   ```

## Troubleshooting

### Supergfxctl Issues

If `supergfxctl -S` fails, ensure you've added:

```nix
systemd.services.supergfxd.path = [ pkgs.pciutils ];
```

### Graphics Switching

Different graphics modes can be set with:

```bash
supergfxctl -m integrated    # Power saving
supergfxctl -m hybrid        # Balance
supergfxctl -m dedicated     # Performance
```

### ROG Control Center

The ROG Control Center should be available in your applications menu. If not:

```bash
systemctl --user status asusd-user
```

## BTRFS Configuration

BTRFS offers benefits like snapshots, compression, and subvolumes. Recommended layout for isolation between system and user data:

```nix
# Add to configuration.nix
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

### Swap Configuration

For optimal performance, especially if you plan to use hibernation, configure a swap partition or file:

**Option A: Swap Partition**

```bash
# Format and enable swap partition
mkswap /dev/nvme0n1p8
swapon /dev/nvme0n1p8
```

**Option B: Swap File**

```bash
# Create swap file on BTRFS
btrfs subvolume create /swap
chattr +C /swap
dd if=/dev/zero of=/swap/swapfile bs=1M count=16384 # 16GB
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile
```

Add to configuration:

```nix
swapDevices = [
  { device = "/dev/nvme0n1p8"; } # Or "/swap/swapfile"
];
```

### BTRFS Maintenance

To maintain BTRFS health and performance, add these periodic tasks to your NixOS configuration:

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

Manual maintenance commands:

```bash
# Check filesystem status
sudo btrfs filesystem usage /

# Balance filesystem (redistribute data)
sudo btrfs balance start -dusage=85 /

# Scrub to detect and repair errors
sudo btrfs scrub start /
# Check progress
sudo btrfs scrub status /
```

## Time Synchronization for Dual-Boot

When dual-booting with Windows, time synchronization issues can occur. Add this to your NixOS configuration to make NixOS compatible with Windows' time handling:

```nix
time.hardwareClockInLocalTime = true;
```

Alternatively, configure Windows to use UTC time:

1. Run Registry Editor (regedit) in Windows
2. Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`
3. Create a new DWORD value named `RealTimeIsUniversal`
4. Set its value to 1

## Backup Strategy

While BTRFS snapshots provide protection against system configuration errors, they're not a complete backup solution. For comprehensive data protection:

1. **System Configuration**: Already covered by NixOS generations
2. **Data Snapshots**: Use `btrbk` or `snapper` to manage BTRFS snapshots
3. **Offsite Backups**: Use restic, borg, or rclone to back up important data to an external drive or cloud service

Add `btrbk` to your NixOS configuration:

```nix
environment.systemPackages = with pkgs; [
  btrbk
];

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

### Method 1: Standard Recovery

If your system fails to boot:

1. Boot from NixOS installation media
2. Mount your BTRFS root partition:

   ```bash
   mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt
   mkdir -p /mnt/{home,nix,boot/efi}
   mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
   mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix
   mount /dev/nvme0n1p1 /mnt/boot/efi
   ```

3. Chroot into your system and fix issues:
   ```bash
   nixos-enter
   ```

### Method 2: Snapshot Recovery

To restore from a BTRFS snapshot:

1. Boot from installation media
2. Mount your root partition: `mount /dev/nvme0n1p7 /mnt`
3. Mount snapshot: `mount -o subvol=.snapshots/123/snapshot /dev/nvme0n1p7 /recovery`
4. Copy files from `/recovery` as needed

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [ASUS-Linux NixOS Guide](https://asus-linux.org/guides/nixos)
- [Supergfxctl Documentation](https://gitlab.com/asus-linux/supergfxctl)
- [Asusctl Documentation](https://gitlab.com/asus-linux/asusctl)
- [NixOS Wiki on Laptops](https://nixos.wiki/wiki/Laptop) - General laptop configuration advice
- [NixOS Hardware Configuration Database](https://github.com/NixOS/nixos-hardware) - Hardware-specific configurations

## Notes

This configuration uses the latest Linux kernel and includes all necessary packages for ASUS ROG laptops. Secrets are managed separately - configure WiFi through the GUI and use .env files for development secrets.

## Bonus: Contributing to nixos-hardware

Once you have your ASUS ProArt P16 working well with NixOS, consider contributing your configuration to the [nixos-hardware](https://github.com/NixOS/nixos-hardware) repository to help other users with the same hardware.

### Creating a Hardware Configuration Module

1. Fork the nixos-hardware repository

2. Create a directory structure for your model:

   ```bash
   mkdir -p asus/proart/p16
   ```

3. Create a basic configuration file at `asus/proart/p16/default.nix`:

   ```nix
   { lib, pkgs, ... }:

   {
     imports = [
       ../../../common/cpu/amd
       ../../../common/gpu/amd
       # Or ../../../common/gpu/nvidia if you have the Nvidia variant
     ];

     # Use latest kernel for best support of ProArt hardware
     boot.kernelPackages = pkgs.linuxPackages_latest;

     # Enable ASUS-specific services
     services = {
       supergfxd.enable = true;
       asusd = {
         enable = true;
         enableUserService = true;
       };
     };

     # Fix for supergfxctl
     systemd.services.supergfxd.path = [ pkgs.pciutils ];

     # Add any other ProArt P16-specific configurations here
   };
   ```

4. Test your configuration thoroughly

5. Submit a Pull Request to the nixos-hardware repository with a detailed description of your model and the changes you've made

This helps build the NixOS ecosystem and makes it easier for future users with the same hardware to get started.
