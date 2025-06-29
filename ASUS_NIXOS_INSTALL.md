# NixOS Installation Guide: ASUS ProArt P16 Setup

This guide provides step-by-step instructions for installing NixOS on an ASUS laptop, using configurations from this dotfiles repository. It covers both manual installation and the Calamares installer.

This guide has been tested with the ASUS ProArt P16 (H7606 series, including H7606WI with AMD Ryzen AI 9 HX 370, NVIDIA RTX 4070, MediaTek MT7922 WiFi, and 4K OLED touchscreen) but should work for most ASUS laptops, including ROG series. Verify compatibility for other models in the [NixOS Hardware Configuration Database](https://github.com/NixOS/nixos-hardware).

## For New Users

If you’re new to NixOS, use the Calamares graphical installer for simplicity. Refer to the [NixOS Manual Getting Started](https://nixos.org/manual/nixos/stable/#sec-installation) for basics. If errors occur during commands like `nixos-rebuild switch`, check `/etc/nixos/configuration.nix` for syntax errors and run `journalctl -p 3 -xb` for logs.

## Prerequisites

- NixOS installation media (24.11 or newer recommended for 2024 ProArt P16 H7606WI)
- Internet connection
- Basic knowledge of NixOS and the command line

## Pre-Installation Steps

### Backup Proprietary eSupport Drivers

If Windows is installed, back up proprietary ASUS drivers before removing Windows partitions:

1. In Windows, copy the entire `C:\eSupport` folder to external storage.
2. These drivers may be needed if you reinstall Windows or use it in a virtual machine.

### Disable Secure Boot

**IMPORTANT FOR DUAL BOOT USERS**: Disable Windows BitLocker first, or your data will be inaccessible!

1. Press DEL repeatedly during boot to enter UEFI setup.
2. Press F7 for advanced mode.
3. Navigate to Security → Secure Boot Control → Disable.
4. Save and exit.

### Use the Laptop Screen

Disconnect external displays during installation to avoid unpredictable behavior with graphics switching.

### Switch to Hybrid Mode on Windows (2022+ Models)

For 2022 or newer ASUS models, including the H7606WI, switch to Hybrid graphics mode in Windows to prevent issues:

1. Open the MyASUS app, go to "Customization" → "GPU Settings," and select "Hybrid Mode" (or "Optimus Mode").
2. Save changes and reboot before installing NixOS.

## Partition Overview

Before installation, review the disk partitions and what to keep for dual-booting with Windows:

| Partition   | Filesystem | Label    | Type                         | Purpose                              | Keep?                  |
| ----------- | ---------- | -------- | ---------------------------- | ------------------------------------ | ---------------------- |
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

1. Check "Encrypt system" when creating the root partition.
2. Set a strong encryption passphrase.
3. The installer handles LUKS setup automatically.

#### With Manual Installation

After creating partitions but before formatting:

1. Set up LUKS2 encryption on your root partition:

   ```bash
   # Create encrypted partition with LUKS2 (default in modern Linux) - you’ll be asked to set a passphrase
   cryptsetup luksFormat --type luks2 /dev/nvme0n1p7

   # Open the encrypted partition
   cryptsetup luksOpen /dev/nvme0n1p7 cryptroot
   ```

   > **Note**: LUKS2 offers better security and is standard in 2025.

2. Format the opened LUKS device:

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

4. Add to your `configuration.nix` after installation:

   ```nix
   boot.initrd.luks.devices = {
     "cryptroot" = {
       device = "/dev/disk/by-uuid/YOUR-UUID-HERE"; # Replace with actual UUID
       preLVM = true;
     };
   };
   ```

   To get the UUID:

   ```bash
   ls -la /dev/disk/by-uuid/
   ```

#### TPM-Based Encryption (Optional)

The ProArt P16 H7606WI has a TPM 2.0 chip, which can be used to unlock the LUKS partition automatically:

1. Ensure TPM is enabled in UEFI setup (BIOS).
2. Install required tools in `configuration.nix`:

   ```nix
   environment.systemPackages = with pkgs; [
     clevis
     tpm2-tools
   ];
   ```

3. After rebuilding and booting, bind the LUKS partition to TPM:

   ```bash
   sudo clevis luks bind -d /dev/nvme0n1p7 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
   ```

4. Update `configuration.nix` for automatic unlocking:

   ```nix
   boot.initrd.luks.devices."cryptroot" = {
     device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
     preLVM = true;
   };
   boot.initrd.systemd.enable = true;
   boot.initrd.clevis.enable = true;
   ```

   **Warning**: Test TPM unlocking thoroughly and maintain a passphrase as a backup. System updates or firmware changes may require re-binding.

### Notes on Encryption and Dual-Boot

- Encryption is independent of Windows BitLocker.
- You can encrypt NixOS partitions with or without Secure Boot.
- For maximum security, consider encrypting both Windows (BitLocker) and NixOS partitions.

## Step 1: Base NixOS Installation

### Option A: Using Calamares Installer (Graphical)

1. Boot from the NixOS installation media (24.11 or newer).
2. Open the Calamares installer via the "Install System" icon.
3. Follow initial setup steps (language, location, keyboard).
4. In the partitioning section:
   - Select **Manual partitioning** for control.
   - **Do NOT format or delete** `nvme0n1p1` through `nvme0n1p5` if preserving Windows.
   - Delete existing Linux partitions (e.g., Fedora’s).
   - Create NixOS partitions:
     - If needed, a `/boot` partition (ext4, ~512MB).
     - A **swap partition** (recommended: 32GB for the H7606WI’s 32GB RAM to handle memory-intensive tasks like video editing or 3D rendering; hibernation not recommended due to firmware limitations).
     - A root partition (`/`) using remaining space (recommended: BTRFS or ext4).
     - **Important**: Calamares formats BTRFS but does not create subvolumes (a limitation in 24.11). Set these up manually post-installation (see below).
   - Mount `nvme0n1p1` (existing EFI partition) at `/boot/efi` but **do NOT format it**.
5. Continue with the installer:
   - Create your user account.
   - Set passwords.
   - Review and confirm settings.
6. Complete installation and reboot.

### Post-Installation BTRFS Setup (Calamares)

Calamares doesn’t create BTRFS subvolumes, so set them up manually to leverage BTRFS features:

1. Boot into your new NixOS system.
2. Create subvolumes and move data:

   ```bash
   # Login as root or use sudo
   sudo -i

   # Create a temporary mount point
   mkdir /mnt/btrfs-root

   # Mount the BTRFS partition
   mount -o subvolid=0 /dev/nvme0n1p7 /mnt/btrfs-root

   # Create subvolumes
   btrfs subvolume create /mnt/btrfs-root/@
   btrfs subvolume create /mnt/btrfs-root/@home
   btrfs subvolume create /mnt/btrfs-root/@nix

   # Copy data to subvolumes (this takes time)
   cp -a --reflink=auto /home/* /mnt/btrfs-root/@home/
   cp -a --reflink=auto /nix/* /mnt/btrfs-root/@nix/
   cp -a --reflink=auto --one-file-system /* /mnt/btrfs-root/@/

   # Update configuration.nix
   nano /etc/nixos/configuration.nix
   ```

   Add to `configuration.nix`:

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

   Rebuild and switch:

   ```bash
   nixos-rebuild switch
   ```

3. Reboot to use the new BTRFS subvolume structure.
4. Proceed to Step 2 (Clone Dotfiles Repository).

### Option B: Manual Installation

1. Boot from NixOS installation media.
2. Check partition layout:

   ```bash
   lsblk -f
   # or
   fdisk -l /dev/nvme0n1
   ```

3. **Preserve** Windows partitions (if dual-booting):
   - **Do NOT** format or delete `nvme0n1p1` through `nvme0n1p5`.
   - `nvme0n1p1` is the shared EFI partition.
4. Delete existing Linux partitions:

   ```bash
   # Example: If p6 and p7 were Fedora partitions
   fdisk /dev/nvme0n1  # Use 'd' to delete
   # Or use cfdisk or gparted
   ```

5. Create new NixOS partitions:

   ```bash
   fdisk /dev/nvme0n1  # Use 'n' to create
   # Or use cfdisk or gparted
   ```

   - A `/boot` partition (if needed, ~512MB).
   - A **swap partition** (recommended: 32GB for the H7606WI’s 32GB RAM).
   - A root partition (`/`) using remaining space.

6. Format new NixOS partitions:

   ```bash
   mkfs.ext4 /dev/nvme0n1p6      # Boot partition (if created)
   # Recommended: Use BTRFS for root
   mkfs.btrfs /dev/nvme0n1p7     # Root partition
   # OR use ext4
   # mkfs.ext4 /dev/nvme0n1p7
   ```

7. Mount partitions:

   **For ext4**:

   ```bash
   mount /dev/nvme0n1p7 /mnt
   mkdir -p /mnt/boot
   mount /dev/nvme0n1p6 /mnt/boot
   mkdir -p /mnt/boot/efi
   mount /dev/nvme0n1p1 /mnt/boot/efi  # Do NOT format!
   ```

   **For BTRFS with subvolumes**:

   ```bash
   mount /dev/nvme0n1p7 /mnt
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   btrfs subvolume create /mnt/@nix
   umount /mnt
   mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt
   mkdir -p /mnt/{home,nix,boot}
   mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
   mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix
   mount /dev/nvme0n1p6 /mnt/boot
   mkdir -p /mnt/boot/efi
   mount /dev/nvme0n1p1 /mnt/boot/efi  # Do NOT format!
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

2. Clone the repository:

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

2. Copy configurations:

   ```bash
   cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/asus-linux/
   cp /mnt/etc/nixos/configuration.nix ./hosts/asus-linux/
   ```

3. Edit the configuration:

   ```bash
   nano hosts/asus-linux/configuration.nix
   ```

4. Add ASUS-specific settings to `configuration.nix`:

   ```nix
   # Use latest kernel for best ASUS hardware support
   boot.kernelPackages = pkgs.linuxPackages_latest;

   # ASUS-specific services
   services = {
     supergfxd.enable = true;
     asusd = {
       enable = true;
       enableUserService = true;
     };
   };

   # Fix for supergfxctl
   systemd.services.supergfxd.path = [ pkgs.pciutils ];

   # NVIDIA configuration
   hardware.nvidia = {
     modesetting.enable = true;
     powerManagement.enable = true;
     package = config.boot.kernelPackages.nvidiaPackages.stable;
   };

   # WiFi and firmware
   hardware.enableAllFirmware = true;
   hardware.firmware = [ pkgs.linux-firmware ];
   boot.kernelModules = [ "mt7921e" "mt7922e" ];

   # Power management
   services.power-profiles-daemon.enable = true;
   services.tlp.enable = lib.mkDefault true;

   # Touchpad and touchscreen
   services.libinput.enable = true;
   hardware.sensor.iio.enable = lib.mkDefault true;
   ```

## ASUS Hardware Management

### Graphics Switching

Manage GPU configuration with `supergfxctl`:

```bash
# Check current graphics mode
supergfxctl -g

# List available modes
supergfxctl -m

# Set graphics mode
supergfxctl -m MODE

# Examples:
supergfxctl -m integrated  # Power-saving (AMD GPU only)
supergfxctl -m hybrid      # Uses both GPUs, NVIDIA on-demand
supergfxctl -m dedicated   # Maximum performance (NVIDIA RTX 4070)
```

**Note**: A logout or reboot is typically required after changing modes. Check the latest `supergfxctl` version (`supergfxctl --version`) at [asus-linux.org](https://asus-linux.org/).

### Keyboard Lighting

Manage the H7606WI’s RGB keyboard with `asusctl`:

```bash
# Set brightness (0-3)
asusctl -k low|med|high|off

# Set RGB mode
asusctl led-mode static     # Single color
asusctl led-mode breathe    # Breathing effect
asusctl led-mode rainbow    # Rainbow effect
# Per-key RGB
asusctl led-mode aura --key red,green,blue
# List modes
asusctl led-mode --help
```

### Power Profiles

Manage power profiles for performance or battery life:

```bash
# Show current profile
asusctl profile -p

# List available profiles
asusctl profile -l

# Set profile
asusctl profile -P quiet|balanced|performance
```

**Note**: Hibernation may fail due to H7606WI firmware limitations (e.g., UEFI or GPU driver issues). Test hibernation:

```bash
systemctl hibernate
```

If it fails, check `dmesg` for errors and verify swap size (32GB recommended). Use suspend-to-idle as a fallback:

```nix
services.logind.lidSwitch = "suspend-then-hibernate";
services.logind.lidSwitchExternalPower = "suspend";
```

Add kernel parameter for better suspend support:

```nix
boot.kernelParams = [ "amd_pstate=active" ];
```

Test: `systemctl suspend`

### Performance Optimization

Optimize the H7606WI for creative workloads (e.g., 4K video editing, 3D rendering):

- **CPU Frequency Scaling**:

  ```nix
  environment.systemPackages = with pkgs; [ cpupower ];
  powerManagement.powertop.enable = true;
  ```

  Set performance governor:

  ```bash
  sudo cpupower frequency-set -g performance
  ```

- **NVIDIA Settings**: Install `nvidia-settings` for fan control or overclocking:

  ```nix
  environment.systemPackages = with pkgs; [ nvidia-settings ];
  ```

  Run: `nvidia-settings` for GUI adjustments.

- **Verify Performance**: Check CPU/GPU usage:

  ```bash
  htop
  nvidia-smi
  ```

### Known Limitations

- If keyboard backlight fails, set a mode: `asusctl led-mode static`.
- Older ROG models (2020) may have NVIDIA GPU low-power issues; the H7606WI is unaffected with recent kernels.
- Use integrated graphics for optimal battery life when not gaming or rendering.
- Switching from NVIDIA to AMD graphics requires a reboot or logout.

### Wayland Support

Wayland (e.g., GNOME, Sway) is increasingly stable for NVIDIA GPUs in 2025, enhancing the H7606WI’s 4K OLED display scaling and HDR. Test with:

```nix
programs.sway.enable = true; # Or GNOME with Wayland
hardware.nvidia.modesetting.enable = true;
```

Test with `supergfxctl -m hybrid`. If USB-C displays fail, fall back to X11:

```nix
services.xserver.enable = true;
services.xserver.displayManager.gdm.wayland = false;
```

### Desktop Environment Integration

For GNOME, add extensions:

```nix
environment.systemPackages = with pkgs; [
  gnomeExtensions.supergfxctl-gex  # GPU mode indicator
  gnomeExtensions.power-profile-switcher  # Power profile controls
];
```

### Additional Configuration

#### Re-enabling Secure Boot (Optional)

To re-enable Secure Boot for the H7606WI:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.loader.secureBoot = {
  enable = true;
  keyFile = "/path/to/secure-boot-key";
  certFile = "/path/to/secure-boot-cert";
};
```

**Steps**:

1. Install `sbctl`:

   ```nix
   environment.systemPackages = with pkgs; [ sbctl ];
   ```

2. Generate and enroll keys:

   ```bash
   sudo sbctl create-keys
   sudo sbctl enroll-keys
   ```

3. Rebuild: `sudo nixos-rebuild switch`
4. Verify in UEFI (DEL key).

**Warning**: Keep a NixOS live USB for recovery if boot fails.

**Recovery**: If Secure Boot fails (e.g., system doesn’t boot):

1. Boot from NixOS live USB.
2. Disable Secure Boot in UEFI (DEL key, Security → Secure Boot Control → Disable).
3. Reset keys if needed: `sudo sbctl reset`.
4. Rebuild: `sudo nixos-rebuild switch`.
   Keep a live USB and backup keys (`/path/to/secure-boot-key`, `/path/to/secure-boot-cert`).

#### Hide Unnecessary Boot Messages

Hide "Nvidia kernel module not found" message:

```nix
systemd.services.nvidia-fallback.enable = false;
```

### Troubleshooting

#### Display Issues

1. **External Displays**:

   - Set GPU mode: `supergfxctl -m dedicated`
   - Use X11 if Wayland fails.

2. **Black Screen After Login**:

   - Switch to TTY (Ctrl+Alt+F3).
   - Check mode: `supergfxctl -g`
   - Try: `supergfxctl -m integrated`

3. **Screen Brightness**:

   - Ensure latest kernel.
   - Add:

     ```nix
     boot.kernelParams = [ "acpi_osi=Linux" ];
     ```

#### Power Management Issues

1. **Poor Battery Life**:

   - Use integrated mode.
   - Enable:

     ```nix
     services.power-profiles-daemon.enable = true;
     services.tlp.enable = true;
     ```

#### Touchpad/Touchscreen Issues

- **Touchpad**: Ensure `services.libinput.enable = true`. Test:

  ```bash
  xinput list
  xinput test <id>
  ```

- **Touchscreen**: The H7606WI’s 4K OLED touchscreen supports stylus input (e.g., ASUS Pen 2.0). Add:

  ```nix
  hardware.sensor.iio.enable = true;
  ```

  Verify:

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

For ASUS Pen 2.0 stylus, test pressure sensitivity in Xournal++ or Krita. If issues occur, check kernel logs:

```bash
dmesg | grep -i input
```

Ensure `i2c_hid_acpi` module is loaded:

```nix
boot.kernelModules = [ "i2c_hid_acpi" ];
```

## Networking Configuration

### WiFi Setup

The H7606WI’s MediaTek MT7922 WiFi card works out of the box with NixOS 24.11. Try the default configuration first:

1. **Basic NetworkManager Setup**:

   ```nix
   networking.networkmanager.enable = true;
   ```

2. Test WiFi:

   ```bash
   nmcli device wifi list
   ```

3. If WiFi fails, identify hardware:

   ```bash
   lspci | grep -i network
   ```

4. Troubleshooting (if needed):

   **For MediaTek MT7922**:

   ```nix
   hardware.enableAllFirmware = true;
   hardware.firmware = [ pkgs.linux-firmware ];
   boot.kernelModules = [ "mt7921e" "mt7922e" ];
   networking.networkmanager.wifi.powersave = false;
   ```

#### WiFi 6E/7 Support

The H7606WI’s MT7922 supports WiFi 6E/7. Test without `iwlwifi.disable_11ax=Y`:

```nix
boot.kernelParams = [ "iwlmvm.power_scheme=1" ]; # Remove disable_11ax
```

Verify performance and connection details:

```bash
iw dev wlan0 link
iperf3 -c <server>
```

If unstable, add:

```nix
boot.kernelParams = [ "iwlwifi.disable_11ax=Y" ];
```

Check for MT7922 firmware updates:

```bash
sudo fwupdmgr refresh
sudo fwupdmgr update
```

5. **Temporary Internet**:
   - Use USB tethering or Ethernet if WiFi fails.

### Bluetooth Configuration

```nix
services.blueman.enable = true;
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;
```

## Verification and Testing

### Hardware Checklist

- Graphics switching: `supergfxctl -g`
- Power profiles: `asusctl profile -p`
- Keyboard backlight: `asusctl -k high`
- WiFi: Connect to a network.
- Bluetooth: Pair a device.
- Function keys: Test volume, brightness, and lighting keys.
- Suspend/Resume: Test with `systemctl suspend`.
- Touchscreen/Stylus: Test in Xournal++ or Krita.

### Quick Diagnostics

```bash
systemctl status asusd supergfxd
lsmod | grep -E 'nvidia|amdgpu'
dmesg | grep -i -E 'error|fail'
glxinfo | grep "OpenGL renderer"
```

## Firmware Updates

### ASUS BIOS Updates

Download BIOS updates from [ASUS Support](https://www.asus.com/support/) for the ProArt P16 H7606WI. Save to a USB drive and follow ASUS’s BIOS update instructions in Windows. If dual-booting isn’t available, use the Windows USB method below.

### Using fwupd in NixOS

```nix
services.fwupd.enable = true;
```

Manage updates:

```bash
systemctl status fwupd
fwupdmgr get-devices
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update
```

**Note**: The H7606WI’s firmware is supported by LVFS. Check [fwupd.org](https://fwupd.org/) for updates specific to this model.

### Creating a Windows USB

For BIOS updates if `fwupd` fails:

1. Create a Windows installation USB.
2. Boot to Windows setup, open Command Prompt (Shift+F10).
3. Run the BIOS update from a USB with update files from ASUS Support.

**Note**: The H7606WI’s hardware is well-supported in recent kernels (6.10+), reducing firmware update frequency.

## Step 4: Update Flake Configuration

1. Edit `flake.nix`:

   ```bash
   nano flake.nix
   ```

2. Add to `nixosConfigurations`:

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

### If Using Calamares

1. Boot into the new system.
2. Proceed to Step 2 (Clone Dotfiles Repository).

### If Using Manual Installation

1. Install:

   ```bash
   nixos-install --flake .#asus-linux
   ```

2. Set root password when prompted.
3. Reboot:

   ```bash
   reboot
   ```

## Step 6: Post-Installation

1. Log in with your user account.
2. Verify ASUS services:

   ```bash
   systemctl status asusd
   systemctl status supergfxd
   ```

3. Check graphics mode:

   ```bash
   supergfxctl -S
   ```

4. Update configuration:

   ```bash
   cd ~/source/dotfiles
   git pull
   sudo nixos-rebuild switch --flake .#asus-linux
   ```

5. System updates with BTRFS:

   ```bash
   sudo btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d)
   sudo nixos-rebuild switch --flake .#asus-linux
   ```

## Dual-Boot Considerations

For dual-booting with Windows:

1. The bootloader (GRUB or systemd-boot) should detect Windows.
2. If Windows doesn’t appear, check:

   ```nix
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;
   boot.loader.systemd-boot.configurationLimit = 10;
   ```

3. Enable NTFS support:

   ```nix
   boot.supportedFilesystems = [ "ntfs" ];
   ```

## Troubleshooting

### NVIDIA Driver Configuration

```nix
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};
```

### Supergfxctl Issues

If `supergfxctl -S` fails:

```nix
systemd.services.supergfxd.path = [ pkgs.pciutils ];
```

### Graphics Switching

```bash
supergfxctl -m integrated
supergfxctl -m hybrid
supergfxctl -m dedicated
```

### ROG Control Center

Check:

```bash
systemctl --user status asusd-user
```

## BTRFS Configuration

Recommended layout:

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

### Swap Configuration

**Option A: Swap Partition (Recommended)**

```bash
mkswap /dev/nvme0n1p8
swapon /dev/nvme0n1p8
```

**Option B: Swap File**

```bash
btrfs subvolume create /swap
chattr +C /swap
dd if=/dev/zero of=/swap/swapfile bs=1M count=32768 # 32GB for H7606WI’s 32GB RAM
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile
```

**Note**: `chattr +C` disables copy-on-write for BTRFS swap files, preventing instability.

Add to `configuration.nix`:

```nix
swapDevices = [
  { device = "/dev/nvme0n1p8"; } # Or "/swap/swapfile"
];
```

### BTRFS Snapshot Configuration

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

Manual maintenance:

```bash
sudo btrfs filesystem usage /
sudo btrfs balance start -dusage=85 /
sudo btrfs scrub start /
sudo btrfs scrub status /
```

## Time Synchronization for Dual-Boot

```nix
time.hardwareClockInLocalTime = true;
```

Alternatively, in Windows:

1. Run `regedit`.
2. Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`.
3. Create DWORD `RealTimeIsUniversal`, set to 1.

## Backup Strategy

1. **System Configuration**: Covered by NixOS generations.
2. **Data Snapshots**: Use `btrbk` or `snapper`.
3. **Offsite Backups**: Use restic, borg, or rclone.

Add `btrbk`:

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

### Method 1: Standard Recovery

1. Boot from NixOS media.
2. Mount BTRFS:

   ```bash
   mount -o subvol=@,compress=zstd /dev/nvme0n1p7 /mnt
   mkdir -p /mnt/{home,nix,boot/efi}
   mount -o subvol=@home,compress=zstd /dev/nvme0n1p7 /mnt/home
   mount -o subvol=@nix,compress=zstd /dev/nvme0n1p7 /mnt/nix
   mount /dev/nvme0n1p1 /mnt/boot/efi
   ```

3. Chroot:

   ```bash
   nixos-enter
   ```

### Method 2: Snapshot Recovery

1. Boot from media.
2. Mount root: `mount /dev/nvme0n1p7 /mnt`
3. Mount snapshot: `mount -o subvol=.snapshots/123/snapshot /dev/nvme0n1p7 /recovery`
4. Copy files from `/recovery`.

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

This configuration uses the latest kernel (6.10+) and packages for ASUS laptops, including the H7606WI. Configure WiFi via GUI and use `.env` files for secrets.

## Bonus: Contributing to nixos-hardware

Contribute your configuration to [nixos-hardware](https://github.com/NixOS/nixos-hardware):

1. Fork the repository.
2. Create directory:

   ```bash
   mkdir -p asus/proart/p16
   ```

3. Create `asus/proart/p16/default.nix`:

   ```nix
   { lib, pkgs, config, ... }:

   {
     imports = [
       ../../../common/cpu/amd
       ../../../common/gpu/amd
       ../../../common/gpu/nvidia
     ];

     boot.kernelPackages = pkgs.linuxPackages_latest;
     services = {
       supergfxd.enable = true;
       asusd = {
         enable = true;
         enableUserService = true;
       };
     };
     systemd.services.supergfxd.path = [ pkgs.pciutils ];
     hardware.nvidia = {
       modesetting.enable = true;
       powerManagement.enable = true;
       package = config.boot.kernelPackages.nvidiaPackages.stable;
     };
     hardware.enableAllFirmware = true;
     hardware.firmware = [ pkgs.linux-firmware ];
     boot.kernelModules = [ "mt7921e" "mt7922e" "i2c_hid_acpi" ];
     services.power-profiles-daemon.enable = true;
     services.tlp.enable = lib.mkDefault true;
     services.libinput.enable = true;
     hardware.sensor.iio.enable = lib.mkDefault true;
   }
   ```

4. Test thoroughly.
5. Submit a Pull Request with details about your ProArt P16 H7606WI (AMD Ryzen AI 9 HX 370, NVIDIA RTX 4070, MediaTek MT7922, 4K OLED touchscreen) and test results, referencing this guide.
