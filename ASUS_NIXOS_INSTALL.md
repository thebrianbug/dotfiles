# NixOS Installation Guide: ASUS ProArt P16

This guide provides step-by-step instructions for installing NixOS on an ASUS laptop, using configurations from this dotfiles repository. It covers both manual installation and the Calamares installer.

This guide has been tested with the ASUS ProArt P16 (H7606 series, including H7606WI with AMD Ryzen AI 9 HX 370, NVIDIA RTX 4070, MediaTek MT7922 WiFi, and 4K OLED touchscreen) and is current for **NixOS 25.05 "Warbler"**. It should work for most ASUS laptops, including ROG series. Verify compatibility for other models in the [NixOS Hardware Configuration Database](https://github.com/NixOS/nixos-hardware).

## For New Users

If you’re new to NixOS, use the Calamares graphical installer for simplicity. Refer to the [Zero-to-Nix Guide](https://zero-to-nix.com/) for basics. If errors occur during commands like `nixos-rebuild switch`, check `/etc/nixos/configuration.nix` for syntax errors and run `journalctl -p 3 -xb` for logs.

## Prerequisites

- NixOS installation media (**25.05 "Warbler"** recommended for the 2024 ProArt P16 H7606WI, as it includes a newer kernel and improved hardware support for recent AMD CPUs and NVIDIA GPUs).
- Internet connection
- Basic knowledge of NixOS and the command line
- An external USB drive or storage device to save backups.

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

### Backup the EFI Partition (CRUCIAL FOR DUAL BOOT)

NixOS generally recommends a 1 GB EFI System Partition (ESP). While it's often possible to use an existing, smaller partition (like your 260 MB Windows-created ESP), this carries a significant space limitation. Because of this, and especially if you have existing EFI entries from other operating systems like Fedora or Windows, **it's highly recommended to back up your current EFI partition before proceeding with the NixOS installation**. You'll perform this essential backup step from the NixOS live USB environment.

1.  **Boot from NixOS Live USB:** Start your laptop and boot from the NixOS installation media. Select the "NixOS graphical installer" or "NixOS (Live)" option.
2.  **Open a Terminal:** Once the live environment loads, open a terminal. You can usually find it in the applications menu or by pressing `Ctrl+Alt+T`.
3.  **Identify your EFI Partition:** Use `lsblk` to list all disks and partitions. Your EFI partition is typically a small FAT32 partition (often around 100-500 MB) with the "esp" or "boot" flag. It's usually mounted at `/boot/efi` if you were booted into Fedora, but in the live environment, it might not be mounted. Look for a partition under a disk (e.g., `/dev/nvme0n1p1` or `/dev/sda1`) with `vfat` filesystem type.
    ```bash
    sudo lsblk -f
    ```
    _Example Output (look for `vfat` and `TYPE="part"`):_
    ```
    NAME        FSTYPE   FSVER LABEL     UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
    nvme0n1
    ├─nvme0n1p1 vfat     FAT32           XXXX-XXXX                                          /boot/efi # This is your EFI partition
    ├─nvme0n1p2 ext4     1.0             YYYY-YYYY                            ...
    └─nvme0n1p3 btrfs              ...
    ```
    In this example, `/dev/nvme0n1p1` is the EFI partition. **Make sure you identify the correct partition for your system.**
4.  **Mount your External Storage:** Connect your external USB drive (or other storage) where you want to save the backup.
    ```bash
    sudo mkdir /mnt/backup_drive
    sudo mount /dev/sdXy /mnt/backup_drive # Replace /dev/sdXy with your external drive's partition (e.g., /dev/sdb1)
    ```
    You can use `sudo lsblk -f` again to identify your external drive's partition.
5.  **Create a Backup Directory:**
    ```bash
    sudo mkdir -p /mnt/backup_drive/efi_backup_$(date +%Y%m%d_%H%M)
    ```
6.  **Mount the EFI Partition and Copy Contents:**
    ```bash
    sudo mkdir /mnt/efi_to_backup
    sudo mount /dev/nvme0n1p1 /mnt/efi_to_backup # Replace /dev/nvme0n1p1 with your EFI partition
    sudo cp -rv /mnt/efi_to_backup/* /mnt/backup_drive/efi_backup_$(date +%Y%m%d_%H%M)/
    ```
    This will copy all files and directories from your EFI partition to the timestamped backup folder on your external drive.
7.  **Verify the Backup:**
    ```bash
    ls -l /mnt/backup_drive/efi_backup_$(date +%Y%m%d_%H%M)/EFI
    ```
    You should see directories like `Microsoft`, `Fedora`, etc., confirming the contents have been copied.
8.  **Unmount Partitions:**
    ```bash
    sudo umount /mnt/efi_to_backup
    sudo umount /mnt/backup_drive
    ```
    Your EFI partition is now safely backed up.

### Clean Old Linux Boot Entries from EFI Partition

Now that you have a backup, you can safely remove old, unused Linux boot entries from your EFI partition using `efibootmgr`. This frees up space and keeps your boot menu clean.

**Note on ASUS EFI Entries:** Your `efibootmgr` output indicates a remarkably clean setup, with **no direct ASUS-specific boot entries** visible in the firmware (like `MyASUS_Booter`). The `MYASUS` partition (`nvme0n1p5`) exists, but its functionality is likely invoked by other means (e.g., specific function keys, or it contains tools not meant to be directly bootable via UEFI entry). This simplifies the cleanup, as you only need to consider Windows and old Linux entries.

1.  **List current boot entries:**

    ```bash
    sudo efibootmgr -v
    ```

    This command will show you a list of boot entries, including their BootOrder (order of booting) and BootXXXX (individual entries). The `-v` flag shows full paths, which helps identify the OS.

    _Based on your provided output, you currently have only two entries:_

    - `Boot0000* Fedora`: Your current Linux installation.
    - `Boot0002* Windows Boot Manager`: Your Windows installation.

    _If you had other old Linux entries (e.g., Ubuntu, Arch, or old Fedora entries), they would appear here._

2.  **Identify Linux-related entries to delete (if any):**
    If your `efibootmgr -v` output had other `BootXXXX` entries besides your current Fedora and Windows Boot Manager, look for entries that correspond to old Linux installations. Common names include:

    - `Ubuntu`
    - `Arch`
    - `GRUB`
    - Any entry whose file path ends with `shimx64.efi` or `grubx64.efi` within a directory named after a Linux distribution (e.g., `\EFI\old_distro_name\shimx64.efi`).

    **\!\!\! CRITICAL WARNING: DO NOT DELETE WINDOWS OR OEM ENTRIES \!\!\!**

    - **Always keep `Windows Boot Manager`**: This entry is crucial for booting Windows. Its path typically points to `\EFI\Microsoft\Boot\bootmgfw.efi`.
    - **Leave any recognized ASUS/OEM/Firmware entries alone** (if they appear). While your specific `efibootmgr` output doesn't show them, other systems might. These might be labeled `MyASUS_Booter`, `Recovery`, `Diagnostics`, `eSupport`, or similar. Deleting them could affect system recovery or manufacturer tools. Their paths often point to `\EFI\ASUS\`, `\EFI\Boot\`, or `\EFI\Recovery\`.
    - **If you are unsure about an entry, DO NOT DELETE IT.** When in doubt, leave it.

3.  **Delete the identified old Linux entries (if any):**
    Use the `efibootmgr -b XXXX -B` command, where `XXXX` is the 4-digit Boot entry number you want to delete.
    _Example (if you had an old "Ubuntu" entry at `Boot0001`):_

    ```bash
    sudo efibootmgr -b 0001 -B
    ```

    Repeat this command for each old Linux entry you want to remove.

4.  **Verify deletion:**
    Run `sudo efibootmgr -v` again to confirm that the unwanted entries are gone from the list. The `BootOrder` should also update.

    Once cleaned, proceed with the rest of the installation steps.

## Partitioning Your ASUS ProArt P16 for NixOS (Dual Boot with Windows)

When installing NixOS alongside Windows, it's critical to **avoid formatting or deleting any existing Windows partitions**. These typically include `nvme0n1p1` through `nvme0n1p5`.

### Understanding Existing Windows Partitions

Your ASUS ProArt P16 likely has the following partition layout. You must **identify and keep all of them**:

| Partition   | Filesystem | Label      | Type                         | Purpose                                        | Keep?      |
| :---------- | :--------- | :--------- | :--------------------------- | :--------------------------------------------- | :--------- |
| `nvme0n1p1` | `vfat`     | `SYSTEM`   | EFI System Partition         | **Shared Bootloader for Windows & NixOS**      | ✅ **Yes** |
| `nvme0n1p2` | _(none)_   | _(none)_   | Microsoft Reserved Partition | Required for Windows (no filesystem)           | ✅ **Yes** |
| `nvme0n1p3` | `ntfs`     | `OS`       | Windows System               | Main Windows installation                      | ✅ **Yes** |
| `nvme0n1p4` | `ntfs`     | `RECOVERY` | Windows Recovery Environment | Recovery tools/partition                       | ✅ **Yes** |
| `nvme0n1p5` | `vfat`     | `MYASUS`   | ASUS Preinstalled Tools      | Manufacturer apps/drivers (separate partition) | ✅ **Yes** |

_Note: Partition numbers (e.g., `nvme0n1p1`) are examples and might vary. Always verify with `lsblk -f` during installation._

## Recommended NixOS Partition Scheme

You'll install NixOS into **free space** on your drive. If you have an existing Linux installation, you can delete its partitions to make room.

Here's the recommended layout for your new NixOS partitions, **especially if you're performing a manual installation**:

1.  **Shared EFI System Partition (`/boot/efi`)**:

    - **Existing Partition**: `nvme0n1p1` (from the table above).
    - **Filesystem**: `vfat`.
    - **Size**: Typically **260 MiB** (your current size) or **1 GB (1024 MiB)** if you perform the optional expansion.
    - **Action**: **DO NOT FORMAT\!** Simply mount this partition at `/boot/efi` during NixOS installation. This allows both Windows and NixOS to share the same bootloader.

    **--- IMPORTANT CONSIDERATION FOR 260 MiB EFI PARTITION ---**
    **If you choose to re-use your existing 260 MiB EFI partition (`nvme0n1p1`) without resizing it, you will typically be limited to keeping only 1 NixOS generation at a time.** This is due to the combined size of Windows boot files, the necessary generic EFI files, and NixOS's kernels/initramfs files (which can easily be 80-120 MiB per generation). **Sacrificing additional generations means you lose NixOS's ability to seamlessly rollback to previous bootable system states directly from the boot menu**, making some system updates riskier.

    To enforce a limit of 1 generation due to space constraints, add the following to your `configuration.nix` file, depending on your bootloader:

    - **For `systemd-boot`**:
      ```nix
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 1; # Limits to 1 generation
      ```
    - **For `GRUB`**:
      ```nix
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.configurationLimit = 1; # Limits to 1 generation
      ```

    **For new users, proceeding with the 260 MiB EFI initially is a valid strategy.** It reduces complexity for your first NixOS installation. NixOS's declarative nature and the ability to keep your configurations in Git provide a strong recovery mechanism for most NixOS-specific issues. If you later desire full multi-generation rollback capabilities, you can consider expanding the EFI partition as an advanced, post-installation step in the
    [Appendix: Advanced EFI Partition Expansion (Optional Post-Installation)](#appendix-advanced-efi-partition-expansion-optional-post-installation).

2.  **Separate `/boot` Partition (`/boot`)**:

    - **Recommendation**: **Strongly recommended for manual installations** when dual-booting with Windows and using BTRFS for your root filesystem. A small, dedicated `/boot` partition (e.g., `ext4`) simplifies bootloader configuration (especially with GRUB) and increases robustness by keeping kernel images and initramfs files on a simpler filesystem, separate from the complex BTRFS root. Your current Fedora setup already uses this robust approach with `nvme0n1p6`.
    - **Size**: **512 MiB**.
    - **Filesystem**: `ext4`.
    - **Action**: Create a new `/boot` partition in the freed space (you can reuse/reformat your existing `nvme0n1p6` for this if it's currently used by Fedora and you plan to replace Fedora).
    - _Note_: While BTRFS can technically house `/boot` within its subvolumes, a dedicated `ext4` `/boot` partition reduces complexity for bootloader setup and maintenance in a dual-boot environment with GRUB. **The Calamares installer may not easily support this specific setup; manual installation is generally preferred for this layout**.

3.  **Swap Partition (`swap`)**:

    - **Recommendation**: Essential for system stability, especially with 32GB RAM.
    - **Size**: **32 GiB** (matching your RAM) is highly recommended for memory-intensive tasks.
    - **Filesystem**: `swap` (no traditional filesystem).
    - **Action**: Create a new swap partition in the freed space.

4.  **NixOS Root Partition (`/`) with BTRFS Subvolumes**:

    - **Recommendation**: **BTRFS** is highly recommended for its advanced features like snapshots, data integrity, and efficient space management.
    - **Size**: **Remaining disk space**. This will hold your NixOS, applications, and user data.
    - **Filesystem**: `btrfs`.
    - **Recommended Subvolumes**:
      - `@`: For the root filesystem (`/`)
      - `@home`: For user home directories (`/home`)
      - `@nix`: For the Nix store (`/nix`), containing all system packages and configurations.
    - _Alternative (ext4)_: If you prefer, you can use `ext4` for your root partition without subvolumes, though BTRFS is generally preferred for new NixOS installations for its flexibility.

### Summary of New NixOS Partitions

Assuming you've freed up space (by removing your old Fedora partitions), your new NixOS partitions (for a **manual installation**) should look like this:

| Partition   | Filesystem | Mount Point | Size          | Purpose                              |
| :---------- | :--------- | :---------- | :------------ | :----------------------------------- |
| `nvme0n1pX` | `ext4`     | `/boot`     | **512 MiB**   | Linux Kernel and Bootloader files    |
| `nvme0n1pY` | `swap`     | `swap`      | **32 GiB**    | Swap space for 32GB RAM              |
| `nvme0n1pZ` | `btrfs`    | `/`         | Remaining     | Main NixOS system with subvolumes    |
| _subvolume_ | `btrfs`    | `/home`     | (part of `/`) | User Home Directories                |
| _subvolume_ | `btrfs`    | `/nix`      | (part of `/`) | Nix Store (packages, configurations) |

_(Replace `nvme0n1pX`, `nvme0n1pY`, `nvme0n1pZ` with the actual partition numbers you create. For your system, `nvme0n1p6` will likely be your new `/boot`, and `nvme0n1p7` your new root.)_

This scheme provides a robust foundation for NixOS while preserving your Windows installation. Refer to the "Manual Installation" steps for creating and mounting these partitions.

---

## Disk Encryption (Optional)

You can encrypt your NixOS installation using LUKS. Skip this section if you don't need encryption.

### Implementing Disk Encryption

#### Using the Calamares Installer

If you're using the Calamares graphical installer:

1.  During partitioning, check **"Encrypt system"** when creating your root partition.
2.  Set a strong encryption passphrase.
3.  Calamares will automatically handle the LUKS setup.
    - _Note_: The `/boot` partition (if separate) is typically left unencrypted.

#### Manual Installation

If you're performing a manual installation, follow these steps _after_ creating your partitions but _before_ formatting:

1.  **Set up LUKS2 encryption** on your root partition (e.g., `/dev/nvme0n1p7`). You'll be prompted to set a passphrase.

    ```bash
    cryptsetup luksFormat --type luks2 /dev/nvme0n1p7
    ```

2.  **Open the encrypted partition**:

    ```bash
    cryptsetup luksOpen /dev/nvme0n1p7 cryptroot
    ```

3.  **Format the opened LUKS device**:

    ```bash
    # For BTRFS (recommended)
    mkfs.btrfs /dev/mapper/cryptroot
    # OR for ext4
    # mkfs.ext4 /dev/mapper/cryptroot
    ```

4.  **Mount the opened LUKS device**:

    ```bash
    mount /dev/mapper/cryptroot /mnt
    ```

5.  After installing NixOS and generating your `hardware-configuration.nix`, **add the following to your `configuration.nix`**:

    ```nix
    boot.initrd.luks.devices = {
      "cryptroot" = {
        device = "/dev/disk/by-uuid/YOUR-LUKS-PARTITION-UUID"; # Replace with the actual UUID of your LUKS partition
        preLVM = true;
      };
    };
    ```

    To find the UUID of your LUKS-formatted partition (e.g., `/dev/nvme0n1p7`):

    ```bash
    ls -la /dev/disk/by-uuid/
    ```

    Look for the UUID corresponding to your LUKS device (e.g., `9abc-1234` for `../../nvme0n1p7`).

#### TPM-Based Encryption (Optional)

Your ProArt P16 H7606WI has a TPM 2.0 chip, which can automatically unlock the LUKS partition at boot without a passphrase.

1.  **Enable TPM** in your UEFI (BIOS) settings.

2.  **Install required tools** in your `configuration.nix`:

    ```nix
    environment.systemPackages = with pkgs; [
      clevis
      tpm2-tools
    ];
    ```

3.  After rebuilding and booting into your system, **bind the LUKS partition to TPM**. Use the _raw device path_:

    ```bash
    sudo clevis luks bind -d /dev/nvme0n1p7 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
    ```

4.  **Update your `configuration.nix`** for automatic unlocking:

    ```nix
    boot.initrd.luks.devices."cryptroot" = {
      device = "/dev/disk/by-uuid/YOUR-LUKS-PARTITION-UUID"; # Replace with the actual UUID
      preLVM = true;
    };
    boot.initrd.systemd.enable = true;
    boot.initrd.clevis.enable = true;
    ```

    **Warning**: TPM unlocking is an advanced feature. Test it thoroughly and **always keep your passphrase as a backup**. Firmware updates or changes to the boot environment may require re-binding the TPM.

### Encryption and Dual-Boot Considerations

- NixOS encryption is separate from Windows BitLocker.
- You can encrypt NixOS partitions with or without Secure Boot enabled.
- For maximum security, consider encrypting both Windows (BitLocker) and NixOS partitions.

## Step 1: Base NixOS Installation

### Option A: Using Calamares Installer (Graphical)

The Calamares installer simplifies the process but has limitations with advanced partitioning layouts, especially for a separate `/boot` partition combined with BTRFS subvolumes. If you want the most robust and flexible partitioning as outlined above (with the separate `ext4` `/boot` partition and multiple NixOS generations), **manual installation (Option B) is highly recommended.**

**Important Note on EFI Partition Size (260 MiB):** If you reuse your existing 260 MiB EFI partition (`nvme0n1p1`) with Calamares, you will likely be **limited to installing only 1 NixOS generation** due to space constraints after accounting for Windows boot files. This compromises NixOS's rollback capabilities. For more generations, consider expanding the EFI partition later as an advanced step (see the dedicated section below).

If you proceed with Calamares, you will likely need to adjust to its supported partitioning options. Calamares typically expects `/boot` to be a directory on your root filesystem or to merge with `/boot/efi` for `systemd-boot`. For BTRFS, it often creates default `@` and `@home` subvolumes.

1.  Boot from the **NixOS 25.05 "Warbler"** installation media.
2.  Launch the Calamares installer ("Install System" icon).
3.  Follow initial setup steps (language, location, keyboard).
4.  In the **partitioning section**:
    - Select **Manual partitioning**.
    - **Do NOT format or delete** `nvme0n1p1` through `nvme0n1p5` (your Windows partitions).
    - Delete any existing Linux partitions to free up space (e.g., your old Fedora partitions `nvme0n1p6` and `nvme0n1p7`).
    - Create your new NixOS partitions in the freed space:
      - An **existing EFI partition (`nvme0n1p1`)** mounted at `/boot/efi` (**do NOT format it**).
      - A **swap partition**: Create a new partition, select "swap" for its filesystem type. Set its size to **32 GiB**.
      - A root partition (`/`) using the remaining space.
        - **If choosing BTRFS:** Create a new partition, select "BTRFS" for its filesystem. Assign it the remaining disk space. Calamares will typically create default `@` and `@home` subvolumes within this. It might not allow you to easily create a separate `ext4` `/boot` partition in addition to `/boot/efi` with BTRFS. If you aim for the `ext4` `/boot` alongside BTRFS, the manual installation is much more straightforward.
        - **If choosing Ext4 for root:** Create a new partition, select "ext4" for its filesystem. Assign it the remaining disk space. In this case, `/boot` will be a directory within your `ext4` root.
5.  Continue the installer, create your user account, set passwords, and confirm settings.
6.  Complete the installation and reboot.

### Post-Installation BTRFS Subvolume Setup (Calamares)

If Calamares installed your NixOS onto a BTRFS partition without creating the specific subvolume layout you desire (e.g., `@`, `@home`, `@nix`), you can manually create and organize them after installation. This involves moving data, so ensure you have backups.

1.  Boot into your new NixOS system.

2.  Create subvolumes and move data (this can take time and disk space):

    ```bash
    # Login as root or use sudo
    sudo -i

    # Create a temporary mount point
    mkdir /mnt/btrfs-root

    # Mount the raw BTRFS partition (replace /dev/nvme0n1p7 with your actual BTRFS partition)
    mount -o subvolid=0 /dev/nvme0n1p7 /mnt/btrfs-root

    # Create desired subvolumes (if they don't already exist from Calamares)
    btrfs subvolume create /mnt/btrfs-root/@
    btrfs subvolume create /mnt/btrfs-root/@home
    btrfs subvolume create /mnt/btrfs-root/@nix

    # Copy data to subvolumes (rsync is safer than cp for this).
    # Exclude temporary and special filesystems, and the destination itself.
    # Adjust paths if Calamares already created some subvolumes.
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run /home/ /mnt/btrfs-root/@home/
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run /nix/ /mnt/btrfs-root/@nix/
    rsync -qaHAX --info=progress2 --exclude=/mnt/btrfs-root --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/var/tmp --exclude=/var/run / /mnt/btrfs-root/@/

    # Update configuration.nix to use the new subvolumes
    nano /etc/nixos/configuration.nix
    ```

    Modify the `fileSystems` block in `configuration.nix` to point to the new subvolumes (replace `/dev/nvme0n1p7` with your actual BTRFS partition):

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
      # The existing EFI partition
      "/boot/efi" = {
        device = "/dev/nvme0n1p1"; # Your existing Windows EFI partition
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ]; # Recommended permissions for EFI
      };
    };
    ```

    Rebuild and activate the new configuration:

    ```bash
    nixos-rebuild switch
    ```

3.  Reboot to ensure the system uses the new BTRFS subvolume structure.

### Option B: Manual Installation

This method gives you full control over partitioning and BTRFS subvolume creation, allowing you to implement the **recommended separate `/boot` partition** setup and manage EFI space precisely.

**Important Note on EFI Partition Size (260 MiB):** If you reuse your existing 260 MiB EFI partition (`nvme0n1p1`) for manual installation, you will typically be **limited to keeping only 1 NixOS generation** due to space constraints after accounting for Windows boot files. This compromises NixOS's rollback capabilities. For more generations, consider expanding the EFI partition later as an advanced step (see the dedicated section below).

1.  Boot from the NixOS installation media.

2.  **Identify existing partitions** and their device paths:

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

3.  **Preserve Windows partitions**: **Do NOT** format or delete `nvme0n1p1` through `nvme0n1p5`. `nvme0n1p1` is your shared EFI partition.

4.  **Delete existing Linux partitions and create new ones:**

    The NixOS live CD includes several partitioning tools such as `fdisk`, `cfdisk`, and `gparted`. While you can use any of these, we will show a detailed example using `cfdisk` due to its user-friendly, curses-based interface.

    ```bash
    sudo cfdisk /dev/nvme0n1
    ```

    Inside `cfdisk`:

    - **Select your disk**: Ensure `/dev/nvme0n1` is selected if prompted.
    - **Delete existing Linux partitions**:
      - Navigate to your existing Linux partitions (e.g., `nvme0n1p6` and `nvme0n1p7` if they are old Fedora partitions).
      - Highlight each one and select `[ Delete ]`. This will mark the space as `Free space`.
    - **Create the new `/boot` partition (512 MiB):**
      - Navigate to the `Free space` where you want to create the `/boot` partition.
      - Select `[ New ]`.
      - Enter `512M` for the size.
      - Select `[ Primary ]` (if prompted, usually auto-selected).
      - Select `[ Type ]` and choose `Linux filesystem`. This will typically be assigned `nvme0n1p6`.
    - **Create the new `swap` partition (32 GiB):**
      - Navigate to the next block of `Free space`.
      - Select `[ New ]`.
      - Enter `32G` for the size (or `32768M`).
      - Select `[ Primary ]`.
      - Select `[ Type ]` and choose `Linux swap`. This will typically be assigned `nvme0n1p7`.
    - **Create the new Root (`/`) partition (remaining space):**
      - Navigate to the remaining `Free space`.
      - Select `[ New ]`.
      - Press `Enter` to accept the default, which will use the `[ Max size ]` (remaining space).
      - Select `[ Primary ]`.
      - Select `[ Type ]` and choose `Linux filesystem`. This will typically be assigned `nvme0n1p8`.
    - **Write changes:**
      - Select `[ Write ]`.
      - Type `yes` and press `Enter` to confirm writing the partition table to disk. **This is the point of no return for changes.**
    - **Quit `cfdisk`:**
      - Select `[ Quit ]`.

5.  **Format new NixOS partitions**:

    ```bash
    mkfs.ext4 /dev/nvme0n1p6     # Your new /boot partition (512 MiB)
    mkswap /dev/nvme0n1p7        # Your new swap partition (32 GiB)
    sudo swapon /dev/nvme0n1p7

    # Recommended: Use BTRFS for root
    mkfs.btrfs /dev/nvme0n1p8     # Your new root partition (Remaining space)
    # OR if using ext4 for root
    # mkfs.ext4 /dev/nvme0n1p8
    ```

6.  **Mount partitions**:

    **For BTRFS with subvolumes (recommended)**:

    ```bash
    # Mount the raw BTRFS partition
    sudo mount /dev/nvme0n1p8 /mnt

    # Create desired subvolumes
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix

    # Unmount the raw partition
    sudo umount /mnt

    # Mount the main root subvolume
    sudo mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p8 /mnt

    # Create mount points for other subvolumes
    sudo mkdir -p /mnt/{home,nix,boot}

    # Mount other subvolumes
    sudo mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p8 /mnt/home
    sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p8 /mnt/nix

    # Mount the separate /boot partition (recommended)
    sudo mount /dev/nvme0n1p6 /mnt/boot

    # Mount the existing EFI partition
    sudo mkdir -p /mnt/boot/efi
    sudo mount -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/boot/efi # Do NOT format!
    ```

    _Note on omitting separate /boot_: If you choose _not_ to create a separate `/boot` partition and place `/boot` directly on the BTRFS root subvolume (`@`), you would simply omit `mount /dev/nvme0n1p6 /mnt/boot` and ensure your `/mnt/boot/efi` is mounted directly. This is generally less robust for dual-boot with GRUB.

7.  **Generate initial NixOS configuration files**:

    ```bash
    sudo nixos-generate-config --root /mnt
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
    # EFI Partition Management: Limit bootloader generations for small EFI partitions
    # If your EFI partition is small (e.g., 260 MiB), you might be limited to
    # keeping only one NixOS generation to avoid running out of space.
    # This limits your rollback capabilities directly from the bootloader.
    # For more generations, consider expanding your EFI partition (see Appendix).
    boot.loader.systemd-boot.configurationLimit = 1; # For systemd-boot
    # boot.loader.grub.configurationLimit = 1;      # For GRUB, if you are using it instead


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

## Appendix: Advanced EFI Partition Expansion (Optional Post-Installation)

This section is for users who have successfully installed NixOS, are comfortable with its basic operation and recovery mechanisms (like Git-backed configs and `nixos-rebuild`), and now wish to enable full multi-generation rollback capabilities by expanding their EFI System Partition (ESP).

**WARNING: This is an advanced and inherently risky procedure.** Incorrect steps can render your system unbootable, including Windows. **Ensure you have full backups of your EFI partition (as performed in "Pre-Installation Steps") and critical data before proceeding.** A NixOS live USB is essential for recovery.

### Why Expand the EFI Partition?

As noted in the "Partitioning" section, a 260 MiB EFI partition, while sufficient for a single NixOS generation alongside Windows, severely limits NixOS's ability to keep multiple bootable generations. Each NixOS generation can consume 80-120 MiB for its kernel and initramfs files within the EFI partition. Expanding the EFI partition to 1 GB (1024 MiB) allows NixOS to store more generations, providing crucial rollback points directly from your bootloader menu, which is one of NixOS's most powerful features.

### Risks Involved

- **Data Loss:** Incorrect partitioning can lead to data loss on any partition, including Windows.
- **Unbootable System:** Modifying the EFI partition or misconfiguring boot entries can prevent both Windows and NixOS from booting.
- **Complex Recovery:** Recovery from EFI issues can be challenging, often requiring a live USB and manual bootloader repairs.

### Mitigations

- **Full EFI Backup:** Crucial. You performed this in the "Pre-Installation Steps." Have it readily available on external media.
- **Data Backups:** Ensure all your critical personal data is backed up before starting.
- **NixOS Live USB:** Keep your NixOS installation media (or any Linux live USB) handy for emergency booting and repairs.
- **Patience and Attention:** Follow each step meticulously. Double-check device paths (`/dev/nvme0n1p1`, etc.) and command syntax.
- **Free Space:** Ensure you have enough unallocated space _immediately adjacent_ to your EFI partition. This typically means shrinking a partition next to it.

### Highly Recommended: Full Disk Backup to External Drive (Crucial for Data Safety)

Before making any changes to your disk partitions, especially for dual-boot installations or EFI partition modifications, it is **extremely important** to create a full image backup of your entire internal SSD. This provides the ultimate safety net, allowing you to restore your system to its exact current state in case of any unforeseen issues.

- **Requirement:** An external drive with storage capacity equal to or greater than your internal SSD (e.g., at least 2 TB for your ProArt P16).
- **Time:** Be prepared for this process to take several hours, depending on the speed of your drives and connection.
- **Recommended Tools:**
  - **Clonezilla:** A free, open-source, and highly reliable disk cloning tool. Boot from a Clonezilla live USB/CD, select disk-to-disk or disk-to-image backup, and follow its guided steps.
  - **`dd` command:** Available in any Linux live environment (including the NixOS live USB). Use with extreme caution as incorrect usage can lead to data loss. Example: `sudo dd if=/dev/nvme0n1 of=/path/to/external_drive/backup.img status=progress bs=4M` (replace `/dev/nvme0n1` with your internal SSD and `/path/to/external_drive/backup.img` with your external drive and desired backup file name).
  - **Windows Imaging Tools:** If primarily backing up Windows, commercial tools like Macrium Reflect Free (if still available) or Acronis True Image can create bootable recovery media.

**Do not proceed with partitioning or installation until this critical backup is complete and verified.**

### Step-by-Step Expansion Process

This process assumes your EFI partition (`nvme0n1p1`) is at the beginning of your disk and you will shrink `nvme0n1p2` (Microsoft Reserved) or `nvme0n1p3` (Windows OS) to create contiguous free space. Shrinking `nvme0n1p2` is generally safer as it's a small, reserved partition, but if `nvme0n1p3` is directly adjacent and large, shrinking it is also an option.

We will use `gparted` from the NixOS live environment for its graphical interface, which reduces the risk of typos compared to command-line tools.

1.  **Boot from NixOS Live USB:**

    - Start your laptop and boot from your NixOS installation media.
    - Select the "NixOS graphical installer" or "NixOS (Live)" option.

2.  **Launch GParted:**

    - Once the live environment loads, open a terminal.
    - Start GParted:
      ```bash
      sudo gparted
      ```

3.  **Shrink an Adjacent Partition:**

    - In GParted, identify your partitions. You'll see `nvme0n1p1` (your 260 MiB EFI).
    - Identify the partition _immediately following_ `nvme0n1p1`. This is likely `nvme0n1p2` (Microsoft Reserved) or `nvme0n1p3` (Windows OS).
    - **Right-click** on the partition you intend to shrink (e.g., `nvme0n1p2` or `nvme0n1p3`).
    - Select **"Resize/Move."**
    - **Carefully adjust the "Free space preceding" or "Free space following"** options to create about **750 MiB** of _unallocated space_ **immediately after `nvme0n1p1`**. The goal is to make `nvme0n1p1` and this new unallocated space contiguous.
      - If shrinking `nvme0n1p2`: Ensure the 750 MiB is created _before_ `nvme0n1p2` by adjusting its starting point.
      - If shrinking `nvme0n1p3`: This is often easier, as you just shrink from its left edge.
    - **Do NOT apply changes yet.** Click "Resize/Move" to confirm the operation, but do not click the green checkmark.

4.  **Resize the EFI Partition (`nvme0n1p1`):**

    - **Right-click** on `nvme0n1p1` (your current 260 MiB EFI partition).
    - Select **"Resize/Move."**
    - Drag the right edge of `nvme0n1p1` to extend it into the newly created unallocated space until it reaches **1024 MiB (1 GB)**.
    - Click "Resize/Move" to confirm.

5.  **Apply All Operations:**

    - Now, click the **green checkmark** (Apply All Operations) in GParted's toolbar.
    - Confirm the warning. GParted will perform the shrinking and resizing operations. This may take some time. **Do not interrupt the process.**

6.  **Verify New Partition Size:**

    - Once GParted finishes, verify that `nvme0n1p1` is now approximately 1 GB.
    - Close GParted.

7.  **Rebuild NixOS Configuration (from Live USB):**

    - Open a terminal and chroot into your NixOS installation.
      - First, identify your NixOS root and `/boot` partitions using `lsblk -f`. Assume `/dev/nvme0n1pX` is your NixOS root (e.g., `nvme0n1p8`) and `/dev/nvme0n1pY` is your separate `/boot` (e.g., `nvme0n1p6`).
      <!-- end list -->
      ```bash
      # Mount your BTRFS root (adjust device path)
      sudo mount -o subvol=@,compress=zstd /dev/nvme0n1p8 /mnt
      sudo mkdir -p /mnt/{home,nix,boot}
      sudo mount -o subvol=@home,compress=zstd /dev/nvme0n1p8 /mnt/home
      sudo mount -o subvol=@nix,compress=zstd /dev/nvme0n1p8 /mnt/nix
      # Mount your separate /boot partition (adjust device path)
      sudo mount /dev/nvme0n1p6 /mnt/boot
      # Mount the now-expanded EFI partition (adjust device path, always nvme0n1p1)
      sudo mkdir -p /mnt/boot/efi
      sudo mount /dev/nvme0n1p1 /mnt/boot/efi
      ```
    - Chroot into the NixOS environment:
      ```bash
      sudo nixos-enter
      ```
    - Navigate to your NixOS configuration files. If you followed the guide, your `dotfiles` are likely mounted under `/mnt/home/your_user/source/dotfiles` or `/mnt/source/dotfiles`. You'll need to mount the containing partition and then `cd` into your dotfiles. For `nixos-enter`, your `/mnt` _is_ `/`.
      ```bash
      # If your dotfiles are at /home/brianbug/source/dotfiles
      cd /home/brianbug/source/dotfiles
      ```
    - **Crucially, set the `configurationLimit` in your `configuration.nix` (within `hosts/asus-linux/configuration.nix`) to a higher value.** This tells NixOS's bootloader (GRUB or systemd-boot) to keep more generations in the EFI partition.

      ```nix
      # Example for systemd-boot
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.configurationLimit = 10; # Keep up to 10 generations

      # Example for GRUB (if you prefer GRUB)
      # boot.loader.grub.enable = true;
      # boot.loader.grub.devices = [ "nodev" ]; # For UEFI systems
      # boot.loader.grub.efiSupport = true;
      # boot.loader.grub.configurationLimit = 10; # Keep up to 10 generations
      ```

    - Rebuild your NixOS system. This will re-install the bootloader files on the now-larger EFI partition.
      ```bash
      nixos-rebuild switch --flake .#asus-linux
      ```
    - Exit the chroot:
      ```bash
      exit
      ```
    - Unmount all partitions:
      ```bash
      sudo umount -R /mnt
      ```

8.  **Reboot and Verify:**

    - Reboot your laptop.
    - Enter the boot menu (usually F8, F10, or F12) or the NixOS bootloader (if systemd-boot) and verify that Windows still appears as a boot option.
    - Boot into NixOS.
    - Perform a few `nixos-rebuild switch` operations to create new generations.
    - Reboot again and check the bootloader menu. You should now see multiple NixOS generations listed.

### Troubleshooting EFI Expansion Issues

If your system fails to boot after EFI partition expansion:

1.  **Boot from NixOS Live USB:** Your live USB is your primary recovery tool.

2.  **Check EFI Partition Health:**

    - Open a terminal and run `sudo fsck.vfat /dev/nvme0n1p1` to check for filesystem errors on the EFI partition.
    - If errors are found, try `sudo fsck.vfat -a /dev/nvme0n1p1` to automatically fix them.

3.  **Restore EFI Backup:**

    - If the partition is corrupted or Windows/NixOS entries are missing and cannot be restored, consider restoring your EFI backup.
    - Mount your external drive containing the backup:
      ```bash
      sudo mkdir /mnt/backup_drive
      sudo mount /dev/sdXy /mnt/backup_drive # Your external USB drive
      ```
    - **Carefully format the EFI partition (LAST RESORT, only if corrupted beyond repair):**
      ```bash
      sudo mkfs.vfat -F 32 /dev/nvme0n1p1
      ```
    - Mount the newly formatted (or existing corrupted) EFI partition:
      ```bash
      sudo mkdir /mnt/efi_target
      sudo mount /dev/nvme0n1p1 /mnt/efi_target
      ```
    - Copy the backup contents back to the EFI partition:
      ```bash
      sudo cp -rv /mnt/backup_drive/efi_backup_YYYYMMDD_HHMM/* /mnt/efi_target/
      ```
      (Replace `YYYYMMDD_HHMM` with your backup's timestamp).
    - Unmount: `sudo umount /mnt/efi_target`

4.  **Reinstall NixOS Bootloader (from Live USB):**

    - Even after restoring the EFI backup, you'll likely need to reinstall the NixOS bootloader.
    - Follow the chroot steps from "Rebuild NixOS Configuration" above to remount your NixOS partitions and `nixos-enter`.
    - Re-run `sudo nixos-rebuild switch --flake .#asus-linux`. This will rewrite the NixOS bootloader entries.

5.  **Manually Add Windows Boot Entry (if missing):**

    - If Windows still doesn't appear after restoring the EFI backup and rebuilding NixOS, you might need to add its boot entry manually using `efibootmgr`.
    - From the live USB, with the EFI partition mounted at `/mnt/boot/efi`:
      ```bash
      sudo efibootmgr -c -d /dev/nvme0n1p1 -p 1 -l \\EFI\\Microsoft\\Boot\\bootmgfw.efi -L "Windows Boot Manager"
      ```
      This command adds a new boot entry for Windows.
      - `-c`: Create a new entry.
      - `-d /dev/nvme0n1p1`: Specify the disk containing the EFI partition.
      - `-p 1`: Specify the partition number (e.g., `nvme0n1p1`).
      - `-l \\EFI\\Microsoft\\Boot\\bootmgfw.efi`: The path to the Windows bootloader.
      - `-L "Windows Boot Manager"`: The label for the boot entry.

6.  **Verify Boot Order:**

    - Check your boot order: `sudo efibootmgr -v`
    - Adjust if necessary to put your preferred OS first: `sudo efibootmgr -o XXXX,YYYY,ZZZZ` (where XXXX,YYYY,ZZZZ are your desired boot entry numbers).

By following these steps carefully, you can successfully expand your EFI partition and gain the full benefits of NixOS's multi-generation rollback capabilities.

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
