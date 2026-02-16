# Disko Disk Layout Analysis

## Overview

All three physical hosts use Disko for declarative disk management with BTRFS subvolumes. Here's a detailed comparison and what happens when re-running Disko.

## Disk Layout Comparison

### jarvis (Desktop Workstation - Dual-boot with Windows)
**Device 1**: `/dev/nvme0n1` (1TB NVMe - shared with Windows)
**Device 2**: `/dev/nvme1n1` (2TB NVMe PCIe5 - K3s storage)
**Total Layout**: Dual-boot configuration (Windows + NixOS + Shared Games)

**⚠️ Note**: This system uses MANUAL partitioning (not Disko) due to dual-boot.
See `JARVIS_INSTALLATION_GUIDE.md` for complete installation instructions.

| Partition | Size | Type | Mount | Options | Purpose |
|-----------|------|------|-------|---------|---------|
| nvme0n1p1 | 100MB | vfat | /boot | fmask=0022, dmask=0022 | UEFI boot (shared with Windows) |
| nvme0n1p3 | 300GB | ntfs | - | - | Windows C: (Windows OS) |
| nvme0n1p4 | 400GB | ntfs | /mnt/games | rw, uid=1000 | Games (D: in Windows, shared) |
| nvme0n1p5 | 16GB | swap | - | randomEncryption | NixOS swap |
| nvme0n1p6 | 284GB | btrfs | / | - | NixOS root (with subvolumes below) |
| @root | - | btrfs | / | compress=zstd, noatime | OS files |
| @home | - | btrfs | /home | compress=zstd, noatime | User files, docs, downloads |
| @nix | - | btrfs | /nix | noatime, nodatacow | Nix packages (performance) |
| @var-log | - | btrfs | /var/log | compress=zstd, noatime | System logs |
| @rancher | - | btrfs | /var/lib/rancher | noatime, nodatacow | K3s worker data |
| @snapshots | - | btrfs | /.snapshots | compress=zstd, noatime | Backups |
| nvme1n1p1 | 2TB | btrfs | /mnt/k3s-storage | compress=zstd, noatime | K3s persistent volumes |

**Swap Size Rationale**: 16GB is sufficient with 64GB RAM (memory pressure relief only)
**Hardware**: AMD Ryzen 9 9900X, NVIDIA RTX 5070Ti, 64GB DDR5

---

### mainframe (K3s Control Plane)
**Device**: `/dev/nvme0n1` (256GB NVMe)
**Total Layout**: EFI (512MB) + Swap (8GB) + BTRFS (remaining)

| Partition | Size | Type | Mount | Options | Purpose |
|-----------|------|------|-------|---------|---------|
| ESP | 512MB | vfat | /boot | fmask=0022 | UEFI boot (smaller for server) |
| swap | 8GB | swap | - | randomEncryption | Minimal swap (headless) |
| @root | auto | btrfs | / | compress=zstd, noatime | OS files |
| @home | auto | btrfs | /home | compress=zstd, noatime | Minimal (server use) |
| @nix | auto | btrfs | /nix | noatime, nodatacow | Nix packages |
| @var-log | auto | btrfs | /var/log | compress=zstd, noatime | System logs |
| @rancher | auto | btrfs | /var/lib/rancher | noatime, nodatacow | **etcd data (CRITICAL)** |
| @snapshots | auto | btrfs | /.snapshots | compress=zstd, noatime | Backups |

**Swap Size Rationale**: 8GB minimal (16GB RAM, headless server)
**Critical**: @rancher with nodatacow is essential for etcd performance!

---

### akasha (Storage Server)
**Device**: `/dev/sda` (512GB SSD)
**Total Layout**: EFI (1GB) + BTRFS (remaining, **NO SWAP**)

| Partition | Size | Type | Mount | Options | Purpose |
|-----------|------|------|-------|---------|---------|
| ESP | 1GB | vfat | /boot | fmask=0022 | UEFI boot |
| @root | auto | btrfs | / | compress=zstd, noatime | OS files |
| @home | auto | btrfs | /home | compress=zstd, noatime | User files |
| @nix | auto | btrfs | /nix | noatime, nodatacow | Nix packages |
| @var-log | auto | btrfs | /var/log | compress=zstd, noatime | System logs |
| @rancher | auto | btrfs | /var/lib/rancher | noatime, nodatacow | K3s worker data |
| @snapshots | auto | btrfs | /.snapshots | compress=zstd, noatime | Backups |

**No Swap**: 64GB RAM is sufficient for server workloads
**Separate ZFS Pool**: 4x 1TB HDDs in RAIDZ1 (managed separately, not by Disko)

---

## Key Differences

| Feature | jarvis | mainframe | akasha |
|---------|--------|-----------|--------|
| **Swap** | 32GB | 8GB | None |
| **Boot** | 1GB | 512MB | 1GB |
| **Device** | /dev/nvme0n1 | /dev/nvme0n1 | /dev/sda |
| **Focus** | Gaming + Desktop | Control Plane | Storage + Compute |
| **@home** | Large (user files) | Minimal | User files |
| **Critical Path** | @rancher (worker) | @rancher (etcd!) | @rancher (worker) |

## Common Mount Options Explained

### compress=zstd
- **What**: BTRFS transparent compression
- **Why**: Saves space, often improves performance (less I/O)
- **Where**: @root, @home, @var-log, @snapshots

### nodatacow (No Copy-on-Write)
- **What**: Disables BTRFS CoW for the subvolume
- **Why**: Better performance for databases, random writes
- **Where**: @nix (many small files), @rancher (etcd/K3s databases)
- **Trade-off**: Loses some BTRFS benefits (snapshots won't work on these)

### noatime
- **What**: Don't update file access times
- **Why**: Reduces writes, improves performance
- **Where**: All subvolumes

### randomEncryption (swap)
- **What**: Encrypts swap with random key (lost on reboot)
- **Why**: Security - prevents hibernation image from containing secrets
- **Trade-off**: Can't hibernate (suspend-to-disk disabled)

---

## What Happens When Re-running Disko?

### ⚠️ WARNING: DISKO IS DESTRUCTIVE ⚠️

When you run Disko with `--mode disko`, it will:

### 1. **Destroy Everything** (No Questions Asked)
```bash
sudo nix run github:nix-community/disko -- --mode disko /path/to/flake#jarvis
```

**What happens**:
- ❌ **Wipes partition table** (GPT destroyed)
- ❌ **Deletes all partitions**
- ❌ **Erases all data** on the disk
- ❌ **Formats filesystems fresh**
- ❌ **No recovery possible** without backups

**Result**: Clean slate, as if you're installing on a brand new disk.

### 2. **Actions Taken** (in order)
1. Unmount any existing filesystems on the device
2. Wipe existing partition table
3. Create new GPT partition table
4. Create partitions (ESP, swap, root)
5. Format ESP as vfat
6. Format swap (with random encryption)
7. Format root partition as BTRFS
8. Create all BTRFS subvolumes (@root, @home, etc.)
9. Mount everything according to the configuration

### 3. **Modes Available**

| Mode | Action | Use Case |
|------|--------|----------|
| `--mode disko` | **DESTROY and recreate** | Fresh install, complete wipe |
| `--mode mount` | Mount existing layout | System already installed with Disko |
| `--mode destroy` | Only destroy, don't create | Cleanup/wipe only |

### 4. **Safe Mode: Mount Only**
```bash
# If you already installed with Disko, use mount mode:
sudo nix run github:nix-community/disko -- --mode mount /path/to/flake#jarvis
```

**What happens**:
- ✅ Mounts existing partitions
- ✅ Mounts all BTRFS subvolumes
- ✅ **NO data loss**
- ✅ Used during system updates, not installation

### 5. **Re-running on Formatted Drive** (Real Scenario)

**Scenario**: You already installed jarvis with Disko, and you run `--mode disko` again.

**What actually happens**:
```
1. Disko detects disk is already formatted
2. Proceeds anyway (no safety checks!)
3. Unmounts all filesystems
4. Destroys partition table
5. Recreates everything from scratch
6. You lose:
   - All your files
   - All your configurations
   - All your user data
   - Your NixOS installation
```

**Outcome**: You need to reinstall everything. It's like a factory reset.

---

## Protection Strategies

### 1. **Wrong Device Protection**
The biggest risk is accidentally running on the wrong disk!

**Check first**:
```bash
# List all disks
lsblk

# Verify the correct device
ls -la /dev/disk/by-id/

# Check what's mounted
mount | grep /dev/
```

**Disko configurations specify**:
- jarvis: `/dev/nvme0n1`
- mainframe: `/dev/nvme0n1`
- akasha: `/dev/sda`

**Override at runtime**:
```bash
# If your device is different:
sudo nix run github:nix-community/disko -- --mode disko \
  --arg disks '{ main = "/dev/nvme0n2"; }' \
  /path/to/flake#jarvis
```

### 2. **Confirmation Before Destruction**
Disko does NOT ask for confirmation. Always:

```bash
# 1. Verify device
lsblk

# 2. Backup if needed
rsync -av /home/user /mnt/backup/

# 3. Double-check the flake reference
nix flake show /path/to/config  # Verify hosts exist

# 4. Dry run (doesn't exist, so be VERY careful)
# There's no dry-run mode for Disko!

# 5. Run Disko
sudo nix run github:nix-community/disko -- --mode disko /path#host
```

### 3. **Existing System Migration**
If you have an existing NixOS system:

**Option A: Don't use Disko for existing systems**
```nix
# In hosts/jarvis/default.nix
imports = [
  # ./disko.nix  # Comment out Disko
  ./hardware-configuration.nix  # Use traditional config
];
```

**Option B: Backup and Reinstall**
```bash
# 1. Backup everything
rsync -av /home /mnt/backup/
rsync -av /etc/nixos /mnt/backup/

# 2. Run Disko (DESTROYS DATA)
sudo nix run github:nix-community/disko -- --mode disko /path#jarvis

# 3. Install NixOS
sudo nixos-install --flake /path#jarvis

# 4. Restore data
rsync -av /mnt/backup/home/ /home/
```

---

## BTRFS Subvolume Benefits

### Why Separate Subvolumes?

1. **Independent Snapshots**
   - Can snapshot @home without @nix
   - Roll back user files separately from system

2. **Different Mount Options**
   - Compress logs, not databases
   - CoW for system, no-CoW for performance-critical

3. **Quota Management**
   - Limit /home size independently
   - Prevent /var/log from filling disk

4. **Backup Strategies**
   - Backup @home frequently
   - Skip @nix (reproducible from config)

### Example: Snapshot Workflow
```bash
# Snapshot home directory before major change
sudo btrfs subvolume snapshot /home /.snapshots/home-$(date +%Y%m%d)

# Make changes...

# Restore if needed
sudo btrfs subvolume delete /home
sudo btrfs subvolume snapshot /.snapshots/home-20260215 /home
```

---

## Recommendations

### For Fresh Installations
✅ Use Disko - it's perfect for reproducible installs

```bash
# Boot NixOS installer
# Clone your config
# Run Disko (one command does everything)
sudo nix run github:nix-community/disko -- --mode disko /mnt/config#jarvis
sudo nixos-install --flake /mnt/config#jarvis
```

### For Existing Systems
⚠️ **DO NOT run Disko unless you want to wipe**

Options:
1. Comment out disko.nix, use hardware-configuration.nix
2. Backup everything and do a clean reinstall
3. Manually convert (complex, not recommended)

### Best Practices

1. **Always specify device explicitly**
   ```bash
   --arg disks '{ main = "/dev/nvme0n1"; }'
   ```

2. **Verify with lsblk FIRST**
   ```bash
   lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
   ```

3. **Never run `--mode disko` on production**
   - Only during initial install
   - Or when you explicitly want to wipe

4. **Use `--mode mount` for maintenance**
   - System already installed
   - Just need to mount partitions

5. **Backup before any Disko operations**
   - ZFS snapshots (for akasha data)
   - rsync critical files
   - Export K3s manifests

---

## Summary

**Disko Layouts**:
- ✅ All hosts have similar BTRFS subvolume structure
- ✅ Optimized per-host (swap sizes, mount options)
- ✅ Fully declarative and version controlled

**Re-running Disko**:
- ⚠️ `--mode disko` = **COMPLETE WIPE**
- ✅ `--mode mount` = Safe, just mounts
- ❌ No dry-run, no confirmation
- 🔥 **Assume data loss** if you run `--mode disko`

**When to Use**:
- ✅ Fresh NixOS installation
- ✅ Deliberate system wipe/rebuild
- ❌ Existing system (use hardware-configuration.nix)
- ❌ "Just to see what happens" (it will destroy data!)

**Protection**:
- Always verify device with `lsblk`
- Backup before any Disko operations
- Use `--mode mount` for existing systems
- Comment out disko.nix if you don't want it
