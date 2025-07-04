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

### Switch to **Standard** Mode (Windows Default / MSHybrid) on Windows (2022+ Models)

For ASUS models from 2022 and newer—including the H7606WI—switch to **Standard** graphics mode (also known as _Windows Default_ or _MSHybrid_) in Windows to avoid potential issues during NixOS installation:

1. Open the **MyASUS** app, navigate to **Customization** → **GPU Settings**, and select **Standard** mode (may also appear as _Optimus Mode_ or _Hybrid Mode_).
2. Save changes and reboot **before** installing NixOS.

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

When installing NixOS alongside Windows, it's critical to **avoid formatting or deleting any existing Windows or vendor partitions**. These typically include `nvme0n1p1` through `nvme0n1p4` and `nvme0n1p7` on your system.

### Understanding Existing Partitions

Based on your disk’s partition layout (from `sudo lsblk -o NAME,FSTYPE,LABEL,UUID,SIZE,FSAVAIL,FSUSE%,MOUNTPOINTS`), your ASUS ProArt P16 has the following partitions. You must **identify and preserve these** to maintain Windows and vendor functionality:

| Partition   | Filesystem | Label    | UUID                                   | Size      | Type                         | Purpose                                      | Keep?      |
| :---------- | :--------- | :------- | :------------------------------------- | :-------- | :--------------------------- | :------------------------------------------- | :--------- |
| `nvme0n1p1` | `vfat`     | `SYSTEM` | `CC14-6473`                            | 260 MiB   | EFI System Partition         | **Shared Bootloader for Windows & NixOS**    | ✅ **Yes** |
| `nvme0n1p2` | _(none)_   | _(none)_ | _(none)_                               | 16 MiB    | Microsoft Reserved Partition | Required for Windows (no filesystem)         | ✅ **Yes** |
| `nvme0n1p3` | `ntfs`     | `OS`     | `D678161C7815FC45`                     | 733.4 GiB | Windows System               | Main Windows installation                    | ✅ **Yes** |
| `nvme0n1p4` | `ntfs`     | _(none)_ | `AAACF0EAACF0B1C5`                     | 1015 MiB  | Windows Recovery Environment | Likely a recovery partition for Windows      | ✅ **Yes** |
| `nvme0n1p5` | `ext4`     | _(none)_ | `54af068c-599e-4fcf-8e44-fc1922b9f1c9` | 1 GiB     | Linux Boot Partition         | Fedora boot partition (kernel, bootloader)   | ❌ **No**  |
| `nvme0n1p6` | `btrfs`    | `fedora` | `0a4fa0cb-bf84-47f5-b9a6-06f4e2a8941e` | 1.1 TiB   | Linux Root Filesystem        | Fedora root and home (to be replaced)        | ❌ **No**  |
| `nvme0n1p7` | `vfat`     | `MYASUS` | `DEB6-CF26`                            | 260 MiB   | ASUS Preinstalled Tools      | Manufacturer apps/drivers (vendor partition) | ✅ **Yes** |

_Note: Always verify your partition layout with `sudo lsblk -o NAME,FSTYPE,LABEL,UUID,SIZE,FSAVAIL,FSUSE%,MOUNTPOINTS` during installation to confirm the correct partitions._

### Recommended NixOS Partition Scheme

You’ll install NixOS into the **free space** created by deleting or reformatting the existing Fedora partitions (`nvme0n1p5` and `nvme0n1p6`). This will provide ~1.1 TiB of space (1 GiB + 1.1 TiB) for NixOS.

Here’s the recommended layout for your new NixOS partitions, tailored for a **manual installation**:

1. **Shared EFI System Partition (`/boot/efi`)**:

   - **Existing Partition**: `nvme0n1p1` (260 MiB, `vfat`, labeled `SYSTEM`).
   - **Action**: **DO NOT FORMAT!** Mount this partition at `/boot/efi` during NixOS installation to share the bootloader with Windows.
   - **Consideration**: The 260 MiB EFI partition may limit you to **1 NixOS generation** due to space constraints (Windows boot files, EFI files, and NixOS kernels/initramfs take ~80-120 MiB per generation). This restricts NixOS’s rollback capability. To enforce 1 generation, add to your `configuration.nix`:
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
   - **Optional Expansion**: For multi-generation support, consider expanding `nvme0n1p1` to ~1 GiB post-installation (see _Appendix: Advanced EFI Partition Expansion_).

2. **Separate `/boot` Partition (`/boot`)**:

   - **Recommendation**: Reuse `nvme0n1p5` (currently 1 GiB, `ext4`) or create a new partition. A dedicated `/boot` partition simplifies bootloader setup (especially with GRUB) in a dual-boot environment with BTRFS.
   - **Size**: Keep at **1 GiB** (current size of `nvme0n1p5` is sufficient).
   - **Filesystem**: `ext4`.
   - **Action**: Reformat `nvme0n1p5` as `ext4` and mount at `/boot`. If you prefer a smaller partition, create a new one (~512 MiB) in the freed space.

3. **Swap Partition (`swap`)**:

   - **Recommendation**: Essential for system stability, especially with 32 GiB RAM.
   - **Size**: **32 GiB** (matching your RAM) for memory-intensive tasks.
   - **Filesystem**: `swap`.
   - **Action**: Create a new swap partition in the freed space (from `nvme0n1p6`).

4. **NixOS Root Partition (`/`) with BTRFS Subvolumes**:
   - **Recommendation**: Reuse the space from `nvme0n1p6` (~1.1 TiB). BTRFS is preferred for its snapshot and data integrity features.
   - **Size**: ~1.1 TiB (remaining space after swap and `/boot`).
   - **Filesystem**: `btrfs`.
   - **Recommended Subvolumes**:
     - `@`: For the root filesystem (`/`).
     - `@home`: For user home directories (`/home`).
     - `@nix`: For the Nix store (`/nix`).
   - **Action**: Delete `nvme0n1p6`, create a new BTRFS partition, and set up subvolumes.
   - **Alternative**: Use `ext4` if you prefer simplicity, but BTRFS is recommended for NixOS.

### Summary of New NixOS Partitions

After deleting `nvme0n1p5` and `nvme0n1p6`, your new NixOS partitions should look like this:

| Partition   | Filesystem | Mount Point | Size          | Purpose                              |
| :---------- | :--------- | :---------- | :------------ | :----------------------------------- |
| `nvme0n1p5` | `ext4`     | `/boot`     | 1 GiB         | Linux Kernel and Bootloader files    |
| `nvme0n1p6` | `btrfs`    | `/`         | ~1.1 TiB      | Main NixOS system with subvolumes    |
| `nvme0n1p8` | `swap`     | `swap`      | 32 GiB        | Swap space for 32 GiB RAM            |
| _subvolume_ | `btrfs`    | `/home`     | (part of `/`) | User Home Directories                |
| _subvolume_ | `btrfs`    | `/nix`      | (part of `/`) | Nix Store (packages, configurations) |

_Note: Partition numbers (`nvme0n1p6`, `nvme0n1p8`) assume you reuse `nvme0n1p5` and create new partitions after deleting `nvme0n1p6`. Adjust numbers based on your partitioning tool’s output._

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

1. Boot from the NixOS installation media.

2. **Identify existing partitions** and their device paths:

   ```bash
   sudo lsblk -o NAME,FSTYPE,LABEL,UUID,SIZE,FSAVAIL,FSUSE%,MOUNTPOINTS
   ```

   Example output:

   ```
   NAME        FSTYPE LABEL  UUID                                   SIZE FSAVAIL FSUSE% MOUNTPOINTS
   zram0       swap   zram0  79a365f1-efde-4487-9eaa-b5642a77ce39     8G                [SWAP]
   nvme0n1                                                          1.9T
   ├─nvme0n1p1 vfat   SYSTEM CC14-6473                              260M  138.6M    46% /boot/efi
   ├─nvme0n1p2                                                       16M
   ├─nvme0n1p3 ntfs   OS     D678161C7815FC45                     733.4G
   ├─nvme0n1p4 ntfs          AAACF0EAACF0B1C5                      1015M
   ├─nvme0n1p5 ext4          54af068c-599e-4fcf-8e44-fc1922b9f1c9     1G  394.4M    53% /boot
   ├─nvme0n1p6 btrfs  fedora 0a4fa0cb-bf84-47f5-b9a6-06f4e2a8941e   1.1T      1T     8% /home
   │                                                                                    /
   └─nvme0n1p7 vfat   MYASUS DEB6-CF26                              260M
   ```

3. **Preserve Windows and vendor partitions**: **Do NOT** format or delete `nvme0n1p1`, `nvme0n1p2`, `nvme0n1p3`, `nvme0n1p4`, or `nvme0n1p7`. `nvme0n1p1` is your shared EFI partition.

4. **Delete existing Linux partitions and create new ones:**

   The NixOS live CD includes partitioning tools like `fdisk`, `cfdisk`, and `gparted`. This example uses `cfdisk` for its user-friendly, curses-based interface.

   ```bash
   sudo cfdisk /dev/nvme0n1
   ```

   Inside `cfdisk`:

   - **Select your disk**: Ensure `/dev/nvme0n1` is selected if prompted.
   - **Delete existing Linux partitions**:
     - Navigate to `nvme0n1p5` and `nvme0n1p6` (current Fedora partitions).
     - Highlight each and select `[ Delete ]` to mark the space as `Free space`.
   - **Reuse or create the `/boot` partition (1 GiB)**:
     - Navigate to the `Free space` where `nvme0n1p5` was (1 GiB).
     - Select `[ New ]` if creating a new partition, or keep existing if reusing.
     - Enter `1G` for the size (or accept existing size).
     - Select `[ Primary ]`.
     - Select `[ Type ]` and choose `Linux filesystem`. This will be `nvme0n1p5`.
   - **Create the new `swap` partition (32 GiB)**:
     - Navigate to the next block of `Free space`.
     - Select `[ New ]`.
     - Enter `32G` for the size.
     - Select `[ Primary ]`.
     - Select `[ Type ]` and choose `Linux swap`. This will be `nvme0n1p6`.
   - **Create the new Root (`/`) partition (remaining space)**:
     - Navigate to the remaining `Free space`.
     - Select `[ New ]`.
     - Press `Enter` to use the `[ Max size ]` (remaining space, ~1.1 TiB).
     - Select `[ Primary ]`.
     - Select `[ Type ]` and choose `Linux filesystem`. This will be `nvme0n1p8`.
   - **Write changes**:
     - Select `[ Write ]`.
     - Type `yes` and press `Enter` to confirm. **This is the point of no return.**
   - **Quit `cfdisk`**:
     - Select `[ Quit ]`.

5. **Format new NixOS partitions**:

   ```bash
   mkfs.ext4 /dev/nvme0n1p5     # /boot partition (1 GiB)
   mkswap /dev/nvme0n1p6        # Swap partition (32 GiB)
   sudo swapon /dev/nvme0n1p6

   # Use BTRFS for root (recommended)
   mkfs.btrfs /dev/nvme0n1p8    # Root partition (~1.1 TiB)
   # OR if using ext4 for root
   # mkfs.ext4 /dev/nvme0n1p8
   ```

6. **Mount partitions**:

   **For BTRFS with subvolumes (recommended)**:

   ```bash
   # Mount the raw BTRFS partition
   sudo mount /dev/nvme0n1p8 /mnt

   # Create subvolumes
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

    # Mount the separate /boot partition
    sudo mount /dev/nvme0n1p5 /mnt/boot

    # Mount the existing EFI partition
    sudo mkdir -p /mnt/boot/efi
    sudo mount -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/boot/efi # Do NOT format!
   ```

_Note on omitting separate /boot_: If you choose _not_ to create a separate `/boot` partition and place `/boot` directly on the BTRFS root subvolume (`@`), you would simply omit `mount /dev/nvme0n1p5 /mnt/boot` and ensure your `/mnt/boot/efi` is mounted directly. This is generally less robust for dual-boot with GRUB.

7. **Generate initial NixOS configuration files**:

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
    { config, pkgs, lib, ... }:

    {
      # Boot configuration
      boot = {
        # EFI Partition Management: Limit bootloader generations for small EFI partitions
        # If your EFI partition is small (e.g., 260 MiB), you might be limited to
        # keeping only one NixOS generation to avoid running out of space.
        # This limits your rollback capabilities directly from the bootloader.
        # For more generations, consider expanding your EFI partition.
        loader.systemd-boot = {
          enable = true;
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
    }
    ```

## ✅ After Adding `asus-linux/configuration.nix`

### 1. Update `flake.nix`

Ensure your flake includes the `asus-linux` host like so:

```nix
nixosConfigurations = {
  asus-linux = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./hosts/asus-linux/configuration.nix
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.brianbug = import ./home-manager/nixos;
      }
    ];
  };
};
```

Replace `brianbug` with your actual username if different.

### 2. Build and Install NixOS

From the root of your flake-based dotfiles repository:

```bash
sudo nixos-install --flake .#asus-linux
```

### 3. Reboot into NixOS

```bash
reboot
```

Log in and verify:

```bash
systemctl status supergfxd asusd
supergfxctl -g
nvidia-smi
```

## 🔁 Keeping Your System Updated

To apply updates or configuration changes:

```bash
cd ~/source/dotfiles
git pull
sudo nix flake update
sudo nixos-rebuild switch --flake .#asus-linux
```

Optionally, create a BTRFS snapshot before updating:

```bash
sudo btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d)
```

## 🧰 Troubleshooting (Modern Hardware)

### Display: Black Screen or No External Monitor

- Use `Ctrl+Alt+F3` to switch to a TTY

- Cycle GPU modes:

  ```bash
  supergfxctl -m hybrid
  supergfxctl -m integrated
  ```

- Fallback to X11 if Wayland fails:

  ```nix
  services.xserver.displayManager.gdm.wayland = false;
  ```

### NVIDIA Issues

> ⚠️ **WARNING: Secure Boot and NVIDIA Drivers**  
> If Secure Boot is enabled in your UEFI settings, the proprietary NVIDIA drivers may silently fail to load. Either:
> - Disable Secure Boot in UEFI settings (recommended for most users)  
> - Or set up signed drivers with `sbctl` (advanced users only)  

If `nvidia-smi` fails:

```bash
lsmod | grep nvidia
dmesg | grep -i nvidia
```

Try forcing dedicated GPU:

```bash
supergfxctl -m dedicated
```

### Audio Problems

```bash
speaker-test -c 2
arecord -l
alsamixer
```

### Wi-Fi / Bluetooth

Check module loading:

```bash
lsmod | grep mt792
```

Restart NetworkManager:

```bash
sudo systemctl restart NetworkManager
```

### Suspend / Hibernate

Check:

```bash
systemctl suspend
free -h
dmesg | grep -i hibernat
```

Ensure swap is ≥ RAM.

## 🛠️ System Recovery (Summary)

### A. Chroot Recovery

Boot from NixOS live USB:

```bash
mount -o subvol=@ /dev/nvme0n1pX /mnt
mount -o subvol=@home /dev/nvme0n1pX /mnt/home
mount -o subvol=@nix /dev/nvme0n1pX /mnt/nix
mount /dev/nvme0n1p1 /mnt/boot/efi
nixos-enter
```

Then rebuild:

```bash
cd ~/source/dotfiles
sudo nixos-rebuild switch --flake .#asus-linux
```

### B. Bootloader Recovery

At boot menu, choose an older generation to roll back. Then:

```bash
sudo nixos-rebuild switch --rollback
```

### C. Snapshot Recovery

Mount snapshot:

```bash
mount -o subvol=.snapshots/123/snapshot /dev/nvme0n1pX /recovery
```

Copy or promote files from `/recovery`.

## 🔋 Power Management Note

In modern setups with:

- `services.asusd.enable = true`
- `services.power-profiles-daemon.enable = true`

You **should not enable** `services.tlp.enable = true`. These conflict. `power-profiles-daemon` is lighter and works natively with GNOME, `asusd`, and dynamic GPU switching.

Remove or comment out:

```nix
# services.tlp.enable = true
```

Stick with:

```nix
services.power-profiles-daemon.enable = true;
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
