# Jarvis Dual-Boot Setup: Windows + NixOS with Disko

## Overview

This document covers how to set up jarvis (AMD Ryzen 9900X desktop) with Windows and NixOS dual-boot using Disko for declarative disk management.

## Hardware Context

**jarvis Specifications**:
- CPU: AMD Ryzen 9 9900X
- GPU: NVIDIA RTX 5070Ti
- Role: Desktop workstation + K3s GPU worker
- Current State: Has Windows installation
- Target: Windows + NixOS dual-boot

## Dual-Boot Scenarios

### Scenario A: Separate Physical Drives (RECOMMENDED)

**Best for**: Clean separation, maximum simplicity, no risk to Windows

```
Drive 1 (NVMe): NixOS only (managed by Disko)
Drive 2 (SSD/NVMe): Windows only (untouched)
```

**Advantages**:
- ✅ Disko manages entire NixOS drive - full declarative control
- ✅ Zero risk to Windows installation
- ✅ Each OS has dedicated drive for optimal performance
- ✅ Easy to reinstall either OS without affecting the other
- ✅ Simplest UEFI boot configuration

**Disadvantages**:
- Requires two physical drives

**Disko Configuration**: Use existing `hosts/jarvis/disko.nix` with correct device path

```nix
# hosts/jarvis/disko.nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";  # NixOS drive (verify with lsblk!)
        # Windows on /dev/nvme1n1 or /dev/sda (completely separate)
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            swap = {
              size = "32G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "nixos" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "noatime" "nodatacow" ];
                  };
                  "@var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@rancher" = {
                    mountpoint = "/var/lib/rancher";
                    mountOptions = [ "noatime" "nodatacow" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
```

**Installation Process**:
```bash
# 1. Boot NixOS installer
# 2. Verify drives
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL

# Expected output:
# nvme0n1     1TB   disk                           # For NixOS
# nvme1n1     1TB   disk                           # For Windows
# └─nvme1n1p1 100M  part           vfat    ESP     # Windows EFI
# └─nvme1n1p2 16M   part                  MSR     # Windows Reserved
# └─nvme1n1p3 900G  part           ntfs    Windows # Windows C:

# 3. Clone config
git clone https://github.com/yourusername/nix-config /mnt/config

# 4. Run Disko on NixOS drive ONLY
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --arg disks '{ main = "/dev/nvme0n1"; }' \
  /mnt/config#jarvis

# 5. Install NixOS
sudo nixos-install --flake /mnt/config#jarvis

# 6. Configure UEFI boot order in BIOS
# Both EFI partitions will be detected
# Set boot priority or use UEFI boot menu (F12/F11)
```

**Boot Configuration**:
```nix
# In hosts/jarvis/default.nix
boot.loader = {
  systemd-boot.enable = true;  # NixOS bootloader on /dev/nvme0n1p1
  efi.canTouchEfiVariables = true;
  timeout = 3;  # Show boot menu for 3 seconds
};

# Optional: Detect Windows EFI partition
boot.loader.systemd-boot.configurationLimit = 20;
boot.loader.efi.efiSysMountPoint = "/boot";
```

---

### Scenario B: Shared Drive - Manual Windows Preservation

**Best for**: Single drive systems, must preserve existing Windows

```
Single Drive (NVMe):
├─ EFI Partition (shared)
├─ Windows MSR
├─ Windows C: (NTFS)
├─ NixOS Swap (created by Disko)
└─ NixOS Root (BTRFS - created by Disko)
```

**Advantages**:
- ✅ Works with single drive
- ✅ Preserves existing Windows installation
- ✅ Shared EFI partition (both OS entries)

**Disadvantages**:
- ⚠️ Cannot use `disko --mode disko` (would wipe Windows!)
- ⚠️ Manual partitioning required before Disko
- ⚠️ More complex setup
- ⚠️ Less declarative (EFI partition not managed by Disko)

**Pre-Installation Steps** (in Windows):
1. **Shrink Windows partition**:
   - Open Disk Management (diskmgmt.msc)
   - Right-click C: → Shrink Volume
   - Shrink by at least 250GB (for NixOS + 32GB swap)
   - Leave space unallocated

2. **Disable Fast Startup**:
   ```
   Control Panel → Power Options → Choose what power buttons do
   → Change settings currently unavailable
   → Uncheck "Turn on fast startup"
   ```

3. **Disable Secure Boot** (temporarily):
   - Reboot to UEFI/BIOS
   - Security → Secure Boot → Disabled
   - Save and exit

**Manual Partitioning** (in NixOS installer):
```bash
# 1. Verify current layout
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL
parted /dev/nvme0n1 print

# Example output:
# nvme0n1         1TB
# ├─nvme0n1p1     100M   vfat   EFI        # Keep (Windows EFI)
# ├─nvme0n1p2     16M           MSR        # Keep (Windows Reserved)
# ├─nvme0n1p3     700G   ntfs   Windows    # Keep (Windows C:)
# └─(unallocated) 300G                     # Use for NixOS

# 2. Create partitions for NixOS
parted /dev/nvme0n1 -- mkpart primary linux-swap 700GB 732GB
parted /dev/nvme0n1 -- mkpart primary btrfs 732GB 100%

# 3. Format swap
mkswap -L swap /dev/nvme0n1p4

# 4. Format BTRFS and create subvolumes manually
mkfs.btrfs -f -L nixos /dev/nvme0n1p5
mount /dev/nvme0n1p5 /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@var-log
btrfs subvolume create /mnt/@rancher
btrfs subvolume create /mnt/@snapshots
umount /mnt

# 5. Mount everything
mount -o compress=zstd,noatime,subvol=@root /dev/nvme0n1p5 /mnt
mkdir -p /mnt/{boot,home,nix,var/log,var/lib/rancher,.snapshots}
mount /dev/nvme0n1p1 /mnt/boot  # Use Windows EFI partition
mount -o compress=zstd,noatime,subvol=@home /dev/nvme0n1p5 /mnt/home
mount -o noatime,nodatacow,subvol=@nix /dev/nvme0n1p5 /mnt/nix
mount -o compress=zstd,noatime,subvol=@var-log /dev/nvme0n1p5 /mnt/var/log
mount -o noatime,nodatacow,subvol=@rancher /dev/nvme0n1p5 /mnt/var/lib/rancher
mount -o compress=zstd,noatime,subvol=@snapshots /dev/nvme0n1p5 /mnt/.snapshots
swapon /dev/nvme0n1p4

# 6. Generate hardware config (captures manual mounts)
nixos-generate-config --root /mnt

# 7. Install NixOS
sudo nixos-install --flake /path/to/config#jarvis
```

**NixOS Configuration** (WITHOUT Disko):
```nix
# hosts/jarvis/default.nix
{
  imports = [
    ./hardware-configuration.nix  # Use generated hardware config instead of disko.nix
    ../../modules/nixos/hardware/cpu-amd.nix
    ../../modules/nixos/hardware/gpu-nvidia.nix
    ../../modules/nixos/services/k3s-nvidia.nix
    ../../modules/nixos/services/nfs-client.nix
  ];

  # Shared EFI partition with Windows
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 5;  # Longer timeout to choose OS
  };

  # K3s agent configuration
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.10.10:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };
}
```

**Note**: You'll need to manually add Windows boot entry if systemd-boot doesn't detect it:
```bash
# After installation, add Windows entry manually
sudo mkdir -p /boot/loader/entries
sudo nano /boot/loader/entries/windows.conf
```

Content:
```
title Windows
efi /EFI/Microsoft/Boot/bootmgfw.efi
```

---

### Scenario C: Shared Drive - Disko with Manual EFI

**Best for**: Want declarative Disko management but need to share drive with Windows

**Approach**: Use Disko but skip EFI partition creation

**Modified Disko Config**:
```nix
# hosts/jarvis/disko-dual-boot.nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # SKIP ESP - already exists from Windows
            # Partition 1: Windows EFI (100MB) - DO NOT TOUCH
            # Partition 2: Windows MSR (16MB) - DO NOT TOUCH
            # Partition 3: Windows C: (NTFS) - DO NOT TOUCH

            swap = {
              start = "700G";  # After Windows partition
              size = "32G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            root = {
              start = "732G";
              end = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "nixos" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # ... rest of subvolumes same as before
                };
              };
            };
          };
        };
      };
    };
    # Manually mount EFI partition (not managed by Disko)
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "defaults" "size=2G" "mode=755" ];
    };
  };

  # Manual EFI mount
  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";  # Windows EFI partition
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
```

**WARNING**: This is advanced and **NOT RECOMMENDED**. Disko may still wipe partitions 1-3. **Backup Windows first!**

---

## Recommendations by Situation

### If You Have Two Physical Drives
→ **Use Scenario A** (separate drives)
- Cleanest, safest, most declarative
- Full Disko support
- Zero risk to Windows

### If You Have One Drive and Want to Keep Windows
→ **Use Scenario B** (manual partitioning)
- Don't use Disko for installation
- Use traditional hardware-configuration.nix
- More work, but safe for Windows

### If You Have One Drive and Can Reinstall Windows Later
→ **Use Scenario A approach** (Disko on entire drive)
1. Backup Windows license key and data
2. Run Disko to wipe entire drive for NixOS
3. After NixOS stable, reinstall Windows on second drive or partition
4. More flexible for future changes

---

## Verification Steps

After installation, verify dual-boot is working:

```bash
# 1. Check boot entries
bootctl list

# Expected output:
# systemd-boot (NixOS)
# Windows Boot Manager (optional)

# 2. Verify mounts
mount | grep /boot
mount | grep btrfs

# 3. Test UEFI boot menu
# Reboot and press F12/F11/ESC (depends on motherboard)
# Should see both NixOS and Windows as options

# 4. Verify BTRFS subvolumes
btrfs subvolume list /

# 5. Check swap
swapon --show
```

---

## Common Issues

### Windows Not Showing in Boot Menu

**Cause**: systemd-boot doesn't auto-detect Windows on different drive

**Solution**: Add manual Windows entry
```bash
sudo nano /boot/loader/entries/windows.conf
```

Content:
```
title Windows 11
efi /EFI/Microsoft/Boot/bootmgfw.efi
```

### Time Desync Between Windows and NixOS

**Cause**: Windows uses local time for RTC, Linux uses UTC

**Solution**: Configure NixOS to use local time
```nix
# In hosts/jarvis/default.nix
time.hardwareClockInLocalTime = true;
```

Or configure Windows to use UTC (better):
```
# In Windows (Run as Administrator in cmd)
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f
```

### NTFS Drives Not Mounting

**Solution**: Add NTFS support to NixOS
```nix
# In hosts/jarvis/default.nix
boot.supportedFilesystems = [ "btrfs" "ntfs" ];
environment.systemPackages = with pkgs; [ ntfs3g ];
```

### Shared EFI Partition Full

**Cause**: Both OS store boot files, systemd-boot keeps old generations

**Solution**: Limit NixOS generations
```nix
boot.loader.systemd-boot.configurationLimit = 10;  # Keep only 10 generations
nix.settings.auto-optimise-store = true;  # Deduplicate /nix/store
```

---

## Next Steps

1. **Determine your scenario**:
   - Run `lsblk` on jarvis to see current drive layout
   - Decide: separate drives (A) or shared drive (B)?

2. **Backup critical data**:
   - Windows C: drive (if on same disk as planned NixOS install)
   - Windows license key (run `slmgr /dli` in Windows)
   - Important documents

3. **Update jarvis configuration**:
   - Use appropriate disko.nix (Scenario A)
   - OR use hardware-configuration.nix (Scenario B)
   - Ensure flake.nix points to correct config

4. **Test in VM first** (optional but recommended):
   - Replicate your disk scenario in VirtualBox/QEMU
   - Verify Disko config works as expected
   - Practice installation process

5. **Proceed with installation**:
   - Follow steps for chosen scenario
   - Verify boot menu shows both OSes
   - Test switching between Windows and NixOS
