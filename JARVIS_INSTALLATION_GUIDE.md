# Jarvis Installation Guide: Windows + NixOS Dual-Boot

## Your Hardware Configuration

**jarvis System Specs**:
- CPU: AMD Ryzen 9 9900X
- GPU: NVIDIA RTX 5070Ti
- RAM: 64GB DDR5
- Storage:
  - **1TB NVMe**: Shared OS drive + Games partition
  - **2TB NVMe PCIe5**: Dedicated K3s storage (BTRFS)

**Disk Layout Plan**:

### 1TB NVMe (/dev/nvme0n1) - OS + Games
```
├─ nvme0n1p1   100MB   EFI (shared by Windows and NixOS)
├─ nvme0n1p2    16MB   MSR (Windows Reserved)
├─ nvme0n1p3   300GB   Windows C: (Windows OS)
├─ nvme0n1p4    16GB   Swap (NixOS swap, small due to 64GB RAM)
├─ nvme0n1p5   300GB   NixOS Root (BTRFS with subvolumes)
└─ nvme0n1p6   ~400GB  Games (NTFS, shared between OSes)
```

### 2TB NVMe PCIe5 (/dev/nvme1n1) - K3s Storage
```
└─ nvme1n1p1   2TB     K3s Storage (BTRFS)
                       Mount: /var/lib/k3s-storage
                       Purpose: Persistent volumes, Longhorn, etc.
```

---

## Installation Order

1. ✅ Install Windows 11 first
2. ✅ Create Games partition in Windows
3. ✅ Shrink Windows partition
4. ✅ Install NixOS using manual partitioning
5. ✅ Configure dual-boot
6. ✅ Format 2TB drive for K3s

---

## Phase 1: Windows Installation

### Step 1.1: Install Windows 11

Boot from Windows 11 USB installer.

**During Installation**:
1. Select the **1TB NVMe drive** for installation
2. Delete any existing partitions if fresh install
3. Create new partition for Windows:
   - Click "New" → Enter 307200 MB (300GB)
   - Windows creates:
     - EFI System Partition (100MB)
     - MSR (16MB)
     - Windows C: (300GB)
4. **DO NOT touch the 2TB NVMe drive!**
5. Install Windows to the C: partition

**After Installation - Verify Disk Layout**:
```
Open Disk Management (diskmgmt.msc):

Disk 0 (1TB NVMe):
├─ EFI System Partition  100MB   FAT32
├─ MSR (Reserved)         16MB
├─ C: (Windows)          300GB   NTFS
└─ Unallocated          ~700GB           ← Will be split for NixOS + Games

Disk 1 (2TB NVMe PCIe5):
└─ Unallocated           2TB             ← Will be for K3s
```

### Step 1.2: Configure Windows

**Disable Fast Startup** (CRITICAL for dual-boot):
```
1. Control Panel → Power Options
2. Choose what the power buttons do
3. Change settings that are currently unavailable
4. Uncheck "Turn on fast startup (recommended)"
5. Save changes
```

**Disable Hibernation** (saves space, prevents NTFS mount issues):
```powershell
# Open PowerShell as Administrator
powercfg /hibernate off
```

**Update Windows**:
```
Settings → Windows Update → Check for updates
Install all updates and reboot
```

### Step 1.3: Create Games Partition

**In Disk Management**:
```
1. Open Disk Management (diskmgmt.msc)
2. Right-click on "Unallocated" space on Disk 0 (1TB)
3. New Simple Volume
   - Size: 409600 MB (400GB for games)
   - Drive letter: D:
   - File system: NTFS
   - Volume label: Games
   - Quick format: Yes
4. Finish
```

**Result**:
```
Disk 0 (1TB):
├─ EFI             100MB   FAT32
├─ MSR              16MB
├─ C: (Windows)    300GB   NTFS
├─ D: (Games)      400GB   NTFS   ← NEW
└─ Unallocated    ~300GB           ← For NixOS
```

### Step 1.4: Disable Secure Boot (Temporarily)

```
1. Reboot to UEFI/BIOS (F2/F12/Del during boot)
2. Security → Secure Boot → Disabled
3. Save and Exit
```

**Note**: Can re-enable after NixOS installation with proper configuration.

---

## Phase 2: NixOS Installation

### Step 2.1: Boot NixOS Installer

Boot from NixOS installation USB.

### Step 2.2: Verify Disk Layout

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT

# Expected output:
# nvme0n1           1TB   disk
# ├─nvme0n1p1       100M  part  vfat    EFI
# ├─nvme0n1p2        16M  part            MSR
# ├─nvme0n1p3       300G  part  ntfs    Windows
# ├─nvme0n1p4       400G  part  ntfs    Games
# └─(unallocated)  ~300G                      ← For NixOS
#
# nvme1n1           2TB   disk
# └─(unallocated)   2TB                       ← For K3s

# Get exact sector info
sudo parted /dev/nvme0n1 unit GB print free
```

### Step 2.3: Create NixOS Partitions

```bash
# Find where free space starts (should be around 700GB)
sudo parted /dev/nvme0n1 unit GB print free

# Example: free space starts at 700GB, ends at 1000GB (1TB)
# Adjust these numbers based on YOUR actual output!

# Create swap partition (16GB - smaller due to 64GB RAM)
sudo parted /dev/nvme0n1 -- mkpart primary linux-swap 700GB 716GB

# Create NixOS root partition (remaining ~284GB)
sudo parted /dev/nvme0n1 -- mkpart primary btrfs 716GB 100%

# Verify partitions
lsblk /dev/nvme0n1
```

**Expected Result**:
```
nvme0n1
├─nvme0n1p1  100M   vfat   EFI
├─nvme0n1p2   16M          MSR
├─nvme0n1p3  300G   ntfs   Windows
├─nvme0n1p4  400G   ntfs   Games
├─nvme0n1p5   16G   swap          ← NEW
└─nvme0n1p6  284G   btrfs         ← NEW
```

### Step 2.4: Format and Mount NixOS Partitions

```bash
# Format swap
sudo mkswap -L swap /dev/nvme0n1p5
sudo swapon /dev/nvme0n1p5

# Format NixOS root as BTRFS
sudo mkfs.btrfs -f -L nixos /dev/nvme0n1p6

# Create BTRFS subvolumes
sudo mount /dev/nvme0n1p6 /mnt
sudo btrfs subvolume create /mnt/@root
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@var-log
sudo btrfs subvolume create /mnt/@rancher
sudo btrfs subvolume create /mnt/@snapshots
sudo umount /mnt

# Mount all subvolumes with proper options
sudo mount -o compress=zstd,noatime,subvol=@root /dev/nvme0n1p6 /mnt

# Create mount points
sudo mkdir -p /mnt/{boot,home,nix,var/log,var/lib/rancher,.snapshots}
sudo mkdir -p /mnt/mnt/{games,k3s-storage}

# Mount EFI partition (shared with Windows)
sudo mount /dev/nvme0n1p1 /mnt/boot

# Mount other BTRFS subvolumes
sudo mount -o compress=zstd,noatime,subvol=@home /dev/nvme0n1p6 /mnt/home
sudo mount -o noatime,nodatacow,subvol=@nix /dev/nvme0n1p6 /mnt/nix
sudo mount -o compress=zstd,noatime,subvol=@var-log /dev/nvme0n1p6 /mnt/var/log
sudo mount -o noatime,nodatacow,subvol=@rancher /dev/nvme0n1p6 /mnt/var/lib/rancher
sudo mount -o compress=zstd,noatime,subvol=@snapshots /dev/nvme0n1p6 /mnt/.snapshots

# Mount Games partition (NTFS, shared with Windows)
sudo mount -t ntfs /dev/nvme0n1p4 /mnt/mnt/games

# Verify all mounts
mount | grep /mnt
df -h | grep /mnt
```

### Step 2.5: Format and Mount 2TB K3s Storage

```bash
# Format 2TB drive as BTRFS for K3s storage
sudo parted /dev/nvme1n1 -- mklabel gpt
sudo parted /dev/nvme1n1 -- mkpart primary btrfs 1MiB 100%

sudo mkfs.btrfs -f -L k3s-storage /dev/nvme1n1p1

# Mount K3s storage
sudo mount /dev/nvme1n1p1 /mnt/mnt/k3s-storage

# Verify
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT | grep nvme1n1
```

### Step 2.6: Clone Your Nix Config

```bash
# Connect to network if needed
sudo systemctl start wpa_supplicant
wpa_cli

# Clone config
git clone https://github.com/yourusername/nix-config /mnt/config
cd /mnt/config
```

### Step 2.7: Generate Hardware Configuration

```bash
# Generate hardware config (captures all mounts)
sudo nixos-generate-config --root /mnt

# This creates /mnt/etc/nixos/hardware-configuration.nix
# Copy it to your flake
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/config/hosts/jarvis/

# Verify it captured all mounts
cat /mnt/config/hosts/jarvis/hardware-configuration.nix
```

### Step 2.8: Install NixOS

```bash
cd /mnt/config

# Install using your flake
sudo nixos-install --flake .#jarvis

# Set root password when prompted
# Set user password when prompted
```

### Step 2.9: Add Windows Boot Entry (if needed)

```bash
# If systemd-boot doesn't auto-detect Windows
sudo mkdir -p /mnt/boot/loader/entries
sudo nano /mnt/boot/loader/entries/windows.conf
```

**Content**:
```
title Windows 11
efi /EFI/Microsoft/Boot/bootmgfw.efi
```

### Step 2.10: Reboot

```bash
sudo reboot
```

---

## Phase 3: Post-Installation Configuration

### Step 3.1: Verify Boot Menu

```bash
# Check boot entries
bootctl list

# Expected:
# - NixOS (default)
# - Windows 11
```

### Step 3.2: Verify All Mounts

```bash
# Check filesystems
df -h

# Expected mounts:
# /              (nvme0n1p6, BTRFS @root)
# /boot          (nvme0n1p1, vfat, shared with Windows)
# /home          (nvme0n1p6, BTRFS @home)
# /nix           (nvme0n1p6, BTRFS @nix, nodatacow)
# /var/log       (nvme0n1p6, BTRFS @var-log)
# /var/lib/rancher (nvme0n1p6, BTRFS @rancher, nodatacow)
# /.snapshots    (nvme0n1p6, BTRFS @snapshots)
# /mnt/games     (nvme0n1p4, NTFS, shared with Windows)
# /mnt/k3s-storage (nvme1n1p1, BTRFS)

# Check swap
swapon --show
```

### Step 3.3: Configure K3s Storage

The 2TB drive is mounted at `/mnt/k3s-storage`. Configure K3s to use it:

```bash
# K3s will use /var/lib/rancher for etcd and system data (on BTRFS @rancher)
# Additional storage provisioner (Longhorn/LocalPath) will use /mnt/k3s-storage

# Create LocalPath provisioner storage directory
sudo mkdir -p /mnt/k3s-storage/local-path-provisioner

# Set permissions
sudo chown -R 1000:1000 /mnt/k3s-storage/local-path-provisioner
```

**Update K3s configuration** (if needed):
```nix
# In hosts/jarvis/default.nix
# K3s LocalPath provisioner will be configured via Kubernetes manifests
# after cluster joins
```

### Step 3.4: Join K3s Cluster

```bash
# Get token from mainframe control plane
# On mainframe:
sudo cat /var/lib/rancher/k3s/server/node-token

# On jarvis, create token file
sudo mkdir -p /var/lib/rancher/k3s
sudo nano /var/lib/rancher/k3s/agent-token
# Paste token from mainframe

# Set permissions
sudo chmod 600 /var/lib/rancher/k3s/agent-token

# Rebuild to enable K3s
sudo nixos-rebuild switch --flake /etc/nixos#jarvis

# Verify K3s agent is running
sudo systemctl status k3s-agent

# On mainframe, check node joined
kubectl get nodes
```

### Step 3.5: Test Shared Games Partition

```bash
# From NixOS
echo "Test from NixOS" > /mnt/games/test-nixos.txt
ls -la /mnt/games/

# Reboot to Windows, verify D:\test-nixos.txt exists
# Create file in Windows: D:\test-windows.txt
# Boot back to NixOS, verify /mnt/games/test-windows.txt exists
```

---

## Final Disk Layout

### After Complete Installation

**Disk 0 (1TB NVMe - /dev/nvme0n1)**:
```
├─ nvme0n1p1   100MB   vfat   EFI (shared: Windows + NixOS)
├─ nvme0n1p2    16MB          MSR (Windows Reserved)
├─ nvme0n1p3   300GB   ntfs   Windows C:
├─ nvme0n1p4   400GB   ntfs   Games (D: in Windows, /mnt/games in NixOS)
├─ nvme0n1p5    16GB   swap   NixOS Swap
└─ nvme0n1p6   284GB   btrfs  NixOS Root
   ├─ @root           → /
   ├─ @home           → /home
   ├─ @nix            → /nix (nodatacow)
   ├─ @var-log        → /var/log
   ├─ @rancher        → /var/lib/rancher (nodatacow, for etcd)
   └─ @snapshots      → /.snapshots
```

**Disk 1 (2TB NVMe PCIe5 - /dev/nvme1n1)**:
```
└─ nvme1n1p1   2TB     btrfs  K3s Storage
                              → /mnt/k3s-storage
                              Purpose: K3s persistent volumes, Longhorn, etc.
```

---

## Usage Patterns

### Gaming

**Windows**: Install games to `D:\Games\` (400GB Games partition)
**NixOS**: Access same games via `/mnt/games/Games/` for Proton/Steam

**Steam Library Setup**:
- Windows: Add library at `D:\Games\SteamLibrary`
- NixOS: Symlink `~/.steam/steam/steamapps → /mnt/games/Games/SteamLibrary`

### K3s Workloads

**Storage Classes**:
1. **Local etcd/K3s data**: `/var/lib/rancher` (BTRFS @rancher, nodatacow)
2. **Persistent Volumes**: `/mnt/k3s-storage` (2TB BTRFS)

**Example LocalPath StorageClass**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-path-config
  namespace: kube-system
data:
  config.json: |
    {
      "nodePathMap": [
        {
          "node": "jarvis",
          "paths": ["/mnt/k3s-storage/local-path-provisioner"]
        }
      ]
    }
```

### Development

**NixOS System**: `/home/youruser/` (on BTRFS @home, compressed)
**Shared Games/Data**: `/mnt/games/` (NTFS, accessible from Windows)
**K3s Storage**: `/mnt/k3s-storage/` (BTRFS, for containers/volumes)

---

## Performance Notes

### Swap Size (16GB with 64GB RAM)

**Why 16GB is enough**:
- 64GB RAM rarely needs swap
- Swap mainly for memory pressure relief
- Suspend-to-disk possible (though not recommended with random encryption)
- Saves ~16GB compared to 32GB swap

**If you need suspend-to-disk**:
- Remove `randomEncryption = true` from swap
- Increase swap to match RAM (64GB)

### BTRFS vs ext4 for K3s Storage

**Current: BTRFS** (chosen for flexibility)
- ✅ Snapshots (backup PVs before changes)
- ✅ Compression (saves space for logs)
- ✅ Subvolumes (separate quotas per app)
- ⚠️ Slightly more CPU overhead

**Alternative: ext4**
```nix
# If you prefer ext4 for K3s storage
fileSystems."/mnt/k3s-storage" = {
  device = "/dev/disk/by-label/k3s-storage";
  fsType = "ext4";
  options = [ "noatime" ];
};
```

**Recommendation**: Start with BTRFS, switch to ext4 if you encounter performance issues.

---

## Troubleshooting

### Games Partition Not Writable from NixOS

```bash
# Check mount options
mount | grep /mnt/games

# Remount with write permissions
sudo umount /mnt/games
sudo mount -t ntfs -o rw,uid=1000,gid=100,dmask=022,fmask=133 /dev/nvme0n1p4 /mnt/games

# Update config in hosts/jarvis/default.nix (already configured)
```

### K3s Storage Not Accessible

```bash
# Verify mount
df -h | grep k3s-storage

# Check permissions
ls -la /mnt/k3s-storage/

# Fix permissions if needed
sudo chown -R 1000:1000 /mnt/k3s-storage/
```

### Time Desync Between Windows and NixOS

Already configured with `time.hardwareClockInLocalTime = true;` in jarvis config.

---

## Summary

**Storage Allocation**:
- Windows OS: 300GB (C:)
- NixOS OS: 284GB (BTRFS with subvolumes)
- Shared Games: 400GB (NTFS, D: / /mnt/games)
- K3s Storage: 2TB (BTRFS, /mnt/k3s-storage)
- Swap: 16GB (small due to 64GB RAM)

**Boot**: Dual-boot via systemd-boot, 5-second timeout
**Time**: Local time for Windows compatibility
**Filesystems**: BTRFS for Linux, NTFS for shared data

**Next Steps**:
1. Install Windows 11 (Phase 1)
2. Create Games partition
3. Install NixOS (Phase 2)
4. Join K3s cluster (Phase 3)
5. Configure storage provisioner for K3s
6. Deploy workloads with GPU support!
