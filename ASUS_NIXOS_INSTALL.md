# NixOS Installation Guide: ASUS Linux Setup

This guide walks you through installing NixOS on an ASUS laptop with all necessary configurations from this dotfiles repository. It includes instructions for both manual installation and using the Calamares installer.

## Prerequisites

- NixOS installation media (latest version recommended)
- Internet connection
- Basic knowledge of NixOS and the command line

## Partition Overview

Before beginning installation, here's a breakdown of disk partitions and what to keep if dual-booting with Windows:

| Partition   | Filesystem | Label    | Type                           | Purpose                              | Keep?       |
| ----------- | ---------- | -------- | ------------------------------ | ------------------------------------ | ----------- |
| `nvme0n1p1` | vfat       | SYSTEM   | EFI System Partition           | Bootloader (shared Fedora + Windows) | ✅ Yes      |
| `nvme0n1p2` | _(none)_   | _(none)_ | Microsoft Reserved Partition   | Required for Windows (no FS)         | ✅ Yes      |
| `nvme0n1p3` | ntfs       | OS       | Windows System                 | Main Windows installation            | ✅ Yes      |
| `nvme0n1p4` | ntfs       | RECOVERY | Windows Recovery Environment   | Recovery tools/partition             | ✅ Optional |
| `nvme0n1p5` | vfat       | MYASUS   | Likely ASUS preinstalled tools | Manufacturer apps/drivers            | 🟡 Optional |

Any existing Linux partitions (like Fedora's `/boot` or root partitions) can be safely removed and replaced with NixOS partitions.

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
     - A root partition (`/`) using the remaining space (ext4 or btrfs)
   - Mount `nvme0n1p1` (the existing EFI partition) at `/boot/efi` but **do NOT format it**
5. Continue with the installer:
   - Create your user account
   - Set passwords
   - Review and confirm installation settings
6. Complete the installation and reboot

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
   mkfs.ext4 /dev/nvme0n1p7      # Root partition
   # OR use btrfs for root if preferred
   # mkfs.btrfs /dev/nvme0n1p7
   ```
7. Mount the partitions:
   ```bash
   mount /dev/nvme0n1p7 /mnt     # Root partition
   mkdir -p /mnt/boot
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

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [ASUS-Linux NixOS Guide](https://asus-linux.org/guides/nixos)
- [Supergfxctl Documentation](https://gitlab.com/asus-linux/supergfxctl)
- [Asusctl Documentation](https://gitlab.com/asus-linux/asusctl)

## Notes

This configuration uses the latest Linux kernel and includes all necessary packages for ASUS ROG laptops. Secrets are managed separately - configure WiFi through the GUI and use .env files for development secrets.
