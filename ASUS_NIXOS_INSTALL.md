# NixOS Installation Guide: ASUS Linux Setup

This guide walks you through installing NixOS on an ASUS laptop with all necessary configurations from this dotfiles repository.

## Prerequisites

- NixOS installation media (latest version recommended)
- Internet connection
- Basic knowledge of NixOS and the command line

## Step 1: Base NixOS Installation

1. Boot from NixOS installation media
2. Partition your disk as needed (using `fdisk`, `cfdisk`, or `gparted`)
3. Format your partitions:
   ```bash
   mkfs.fat -F32 /dev/nvme0n1p1  # EFI partition
   mkfs.ext4 /dev/nvme0n1p2      # Root partition
   ```
4. Mount the partitions:
   ```bash
   mount /dev/nvme0n1p2 /mnt
   mkdir -p /mnt/boot/efi
   mount /dev/nvme0n1p1 /mnt/boot/efi
   ```
5. Generate initial configuration:
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
2. Copy hardware configuration:
   ```bash
   cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/asus-linux/
   ```
3. Create `configuration.nix`:
   ```bash
   cp hosts/vm/configuration.nix hosts/asus-linux/
   ```
4. Edit the configuration file:

   ```bash
   nano hosts/asus-linux/configuration.nix
   ```

5. Update the following settings:

   ```nix
   networking.hostName = "asus-linux";

   # Update bootloader settings - for UEFI systems:
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;

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
