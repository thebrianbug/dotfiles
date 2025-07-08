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

1.  Open the **MyASUS** app, navigate to **Customization** → **GPU Settings**, and select **Standard** mode (may also appear as _Optimus Mode_ or _Hybrid Mode_).
2.  Save changes and reboot **before** installing NixOS.

> NOTE: You CANNOT currently switch the graphics mode except inside Windows and in the MyASUS app\! As long as this is the case, completely removing the Windows partition is not recommended in case you need to switch the graphics mode again in the future.

### Backup the EFI Partition (CRUCIAL FOR DUAL BOOT)

The EFI System Partition (ESP) is essential for booting your operating systems. While NixOS generally recommends a 1 GB ESP, your existing Windows-created ESP is likely smaller (e.g., 260 MB). This smaller size can become a limitation, especially if you want to keep multiple NixOS generations for rollback capabilities, as each generation stores its kernel and initramfs on the ESP.

**It is highly recommended to back up your current EFI partition before proceeding with the NixOS installation.** This step is crucial for recovery in case of accidental data loss or boot issues. You'll perform this essential backup step from the NixOS live USB environment.

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
    ├─nvme0n1p1 vfat     FAT32           XXXX-XXXX                                     /boot/efi # This is your EFI partition
    ├─nvme0n1p2 ext4     1.0             YYYY-YYYY                               ...
    └─nvme0n1p3 btrfs                    ...
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

**Note on ASUS EFI Entries:** Your `efibootmgr` output indicates a remarkably clean setup, with **no direct ASUS-specific boot entries** visible in the firmware (like `MyASUS_Booter`). The `MYASUS` partition (`nvme0n1p7`) exists, but its functionality is likely invoked by other means (e.g., specific function keys, or it contains tools not meant to be directly bootable via UEFI entry). This simplifies the cleanup, as you only need to consider Windows and old Linux entries.

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

You’ll install NixOS into the **free space** created by deleting or reformatting the existing Fedora partitions (`nvme0n1p5` and `nvme0n1p6`). This will provide \~1.1 TiB of space (1 GiB + 1.1 TiB) for NixOS.

Here’s the recommended layout for your new NixOS partitions, tailored for a **manual installation**:

1.  **Shared EFI System Partition (`/boot/efi`)**:

    - **Existing Partition**: `nvme0n1p1` (260 MiB, `vfat`, labeled `SYSTEM`).
    - **Action**: **DO NOT FORMAT\!** Mount this partition at `/boot/efi` during NixOS installation to share the bootloader with Windows.
    - **Consideration for smaller EFI Partition**: Your 260 MiB EFI partition (`nvme0n1p1`) is smaller than the recommended 1 GB. This can limit the number of NixOS generations you can keep, as each generation's kernel and initramfs files are stored here (Windows boot files and EFI files also consume space).
      - **Mitigation Strategy (Recommended): Use a Separate Boot Partition and GRUB.** To effectively mitigate the size limitation of your smaller EFI partition, you can use a separate `/boot` partition (as described in point 2 below) and the GRUB bootloader. With GRUB, the EFI partition primarily needs to store GRUB's EFI executable, which is much smaller, allowing you to store multiple kernel generations on the larger `/boot` partition. This is the recommended approach for dual-boot setups with a small existing ESP.
      - **Advanced Option (Not Recommended for beginners): Resize the EFI Partition.** You could attempt to resize `nvme0n1p1` to a larger size (e.g., 1 GB) using a partitioning tool. However, **this is an advanced option and carries a significant risk of data loss and potential unbootable systems if not done correctly.** It involves shrinking adjacent partitions and expanding the EFI partition. Proceed with extreme caution and only if you are confident in your partitioning skills, and ensure you have a full system backup.
      - **If you stick with systemd-boot on a small ESP**: You would need to limit NixOS generations to 1 to avoid running out of space. Add to your `configuration.nix`:
        ```nix
        boot.loader.systemd-boot.enable = true;
        boot.loader.systemd-boot.configurationLimit = 1; # Limits to 1 generation
        ```

2.  **Separate `/boot` Partition (`/boot`)**:

    - **Recommendation**: Reuse `nvme0n1p5` (currently 1 GiB, `ext4`) or create a new partition. A dedicated `/boot` partition is highly recommended when your EFI partition is small and you wish to maintain multiple NixOS generations, especially when using GRUB. This allows the kernels and initramfs files to reside on a larger partition.
    - **Size**: Keep at **1 GiB** (current size of `nvme0n1p5` is sufficient).
    - **Filesystem**: `ext4`.
    - **Action**: Reformat `nvme0n1p5` as `ext4` and mount at `/boot`. If you prefer a smaller partition, create a new one (\~512 MiB) in the freed space.
    - **Configuration for GRUB with separate `/boot`**:
      ```nix
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.device = "inherit"; # Tells GRUB to install to the EFI partition
      boot.loader.grub.extraGrubConfig = ''
        GRUB_CMDLINE_LINUX_DEFAULT="splash loglevel=4"
        GRUB_ENABLE_CRYPTODISK=y
      '';
      # No configurationLimit needed for GRUB here as kernels are on /boot
      ```

3.  **Swap Partition (`swap`)**:

    - **Recommendation**: Essential for system stability, especially with 32 GiB RAM.
    - **Size**: **32 GiB** (matching your RAM) for memory-intensive tasks.
    - **Filesystem**: `swap`.
    - **Action**: Create a new swap partition in the freed space (from `nvme0n1p6`).

4.  **NixOS Root Partition (`/`) with BTRFS Subvolumes**:

    - **Recommendation**: Reuse the space from `nvme0n1p6` (\~1.1 TiB). BTRFS is preferred for its snapshot and data integrity features.
    - **Size**: \~1.1 TiB (remaining space after swap and `/boot`).
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
| `nvme0n1p6` | `btrfs`    | `/`         | \~1.1 TiB     | Main NixOS system with subvolumes    |
| `nvme0n1p8` | `swap`     | `swap`      | 32 GiB        | Swap space for 32 GiB RAM            |
| _subvolume_ | `btrfs`    | `/home`     | (part of `/`) | User Home Directories                |
| _subvolume_ | `btrfs`    | `/nix`      | (part of `/`) | Nix Store (packages, configurations) |

_Note: Partition numbers (`nvme0n1p6`, `nvme0n1p8`) assume you reuse `nvme0n1p5` and create new partitions after deleting `nvme0n1p6`. Adjust numbers based on your partitioning tool’s output._

### Implementing Disk Encryption

You can encrypt your NixOS installation using LUKS. Skip this section if you don't need encryption.

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

    > ⚠️ **IMPORTANT TPM RECOVERY WARNING**
    >
    > **Always retain your manual LUKS passphrase as a critical fallback!** TPM-based unlocking will fail in these scenarios:
    >
    > - After BIOS/firmware updates (which reset TPM state)
    > - After certain hardware changes or maintenance
    > - Following boot environment modifications
    > - If the TPM chip malfunctions
    >
    > **Recovery Procedure:** When TPM unlocking fails, you'll be prompted for your manual passphrase.
    > After booting successfully with your passphrase, rebind the TPM:
    >
    > ```bash
    > sudo clevis luks bind -d /dev/nvme0n1p7 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
    > ```
    >
    > **Always test TPM unlocking** after binding before relying on it exclusively.

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
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, lib, ... }: # Added 'lib' for potential future use, standard practice

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot = {
    # Bootloader configuration
    loader = {
      # Use GRUB for better compatibility with small EFI partitions and dual-booting.
      # This allows kernel generations to be stored on a separate /boot partition.
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        device = "nodev"; # Required for EFI install with separate /boot partition
        # No configurationLimit here, as kernels are stored on the separate /boot partition
      };

      # Mount point for the shared EFI System Partition (ESP)
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };

      # The systemd-boot configuration is removed here because we are using GRUB
      # as the primary bootloader to manage the smaller EFI partition more effectively.
      # If you were to use systemd-boot with a small EFI partition (e.g., 260 MiB),
      # you would typically need to enable it here and set configurationLimit = 1.
      # loader.systemd-boot = {
      #   enable = true; # Allow NixOS to write its bootloader to the EFI partition
      #   configurationLimit = 1; # Keep only one generation to save space
      # };
    };

    # Use latest stable kernel for best hardware support
    # Note: Modern kernels auto-load most required modules for ASUS laptops
    kernelPackages = pkgs.linuxPackages_latest;

    # Essential kernel parameters
    kernelParams = [
      "nvidia-drm.modeset=1" # Enable NVIDIA DRM for better compatibility with Wayland
      "amd_pstate=active" # Essential power management for AMD CPUs (Ryzen)
    ];
  };

  # Services configuration
  services = {
    # Unified ASUS hardware control
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
    iio-sensor-proxy.enable = true; # Auto-rotation, light sensor (moved from systemPackages)

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

    # GNOME desktop with Wayland (for best HDR support and NVIDIA compatibility)
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ]; # Ensure NVIDIA driver is loaded by X server
    };
  };

  # Essential environment variables for NVIDIA+Wayland
  environment.variables = {
    GBM_BACKEND = "nvidia-drm"; # Required for GNOME Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # OpenGL vendor selection for NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes cursor issues in Wayland
  };

  # System diagnostic and hardware tools
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    inxi
    glxinfo # Hardware Debugging

    # Other system tools here
  ];

  programs.firefox.enable = true; # Link Firefox and enable system-wide

  # Firmware for hardware components
  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable; # Use stable driver
      modesetting.enable = true; # Required for Wayland compatibility

      powerManagement = {
        enable = true;
        finegrained = true; # Better power management for laptops
      };

      open = false; # Prefer proprietary driver for NVIDIA
      nvidiaSettings = true;
      forceFullCompositionPipeline = true; # Eliminates screen tearing (moved back here)

      # PRIME offloading for demanding apps only.
      # It is highly recommended to DISABLE prime offloading until AFTER a
      # successful first install to simplify initial setup and debugging.
      # Uncomment and configure this section after verifying your base NixOS installation.
      prime = {
        offload.enable = false; # Set to 'true' after first successful install
        sync.enable = false;    # Set to 'true' if you experience tearing with offload enabled later

        # PCI bus IDs for hybrid graphics (verify with 'lspci -k | grep -EA3 'VGA|3D|Display'')
        # Replace these with your actual IDs
        amdgpuBusId = "PCI:65:00:0"; # Example ID, verify on your system after first install
        nvidiaBusId = "PCI:64:00:0"; # Example ID, verify on your system after first install
      };
    };

    enableAllFirmware = true; # Auto-detect needed firmware
    firmware = with pkgs; [
      linux-firmware # Broad hardware support
      sof-firmware # Better audio support
    ];

    # Enable hardware acceleration with Mesa support for AMD GPU
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ mesa ];
    };

    bluetooth.enable = true;
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

  services.printing.enable = true;

  # Configure Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.brianbug = import ../../home-manager/nixos;
    backupFileExtension = "backup";
  };

  # This is what makes the home-manager configuration work with the user's packages
  programs.zsh.enable = true; # or bash if you're using bash

  system.stateVersion = "25.05"; # Use your generated version here; DO NOT CHANGE after install, see `man configuration.nix`
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
>
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
