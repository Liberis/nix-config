# Jarvis Server Installation Guide

Fully automated NixOS installation using Disko for the Jarvis homelab server.

## Prerequisites

1. NixOS minimal ISO (USB drive)
2. Target machine (Lenovo P510 with 512GB SSD)
3. Network connection
4. This flake repository

## Installation Steps

### 1. Boot NixOS Installer

Boot from the NixOS USB drive.

### 2. Setup Network

```bash
# If using WiFi
sudo systemctl start wpa_supplicant
wpa_cli

# If using Ethernet, it should work automatically
ping nixos.org
```

### 3. Identify Target Disk

```bash
lsblk
# Find your 512GB SSD (likely /dev/sda or /dev/nvme0n1)
```

### 4. Clone Configuration

```bash
# Install git
nix-shell -p git

# Clone your config
git clone https://github.com/YOUR_USERNAME/nix-config /tmp/nix-config
cd /tmp/nix-config
```

### 5. Run Disko (Automated Partitioning)

**IMPORTANT**: This will ERASE ALL DATA on the target disk!

```bash
# Basic installation (assuming /dev/sda)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
  -- --mode disko /tmp/nix-config#jarvis

# If your disk is different (e.g., /dev/nvme0n1):
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
  -- --mode disko --arg disks '{ main = "/dev/nvme0n1"; }' /tmp/nix-config#jarvis
```

This will:
- Partition the disk (1GB EFI + rest BTRFS)
- Format filesystems
- Create BTRFS subvolumes (@root, @home, @nix, @var-log, @rancher, @snapshots)
- Mount everything at /mnt

### 6. Install NixOS

```bash
# Install with the flake
sudo nixos-install --flake /tmp/nix-config#jarvis

# Set root password when prompted
```

### 7. Reboot

```bash
sudo reboot
```

### 8. Post-Installation

After first boot:

```bash
# Login as liberis (password set during install or via SSH)

# Check BTRFS layout
sudo btrfs filesystem show
sudo btrfs subvolume list /

# Verify quotas are set
sudo btrfs qgroup show /

# Check compression ratio
sudo compsize /

# Verify K3s is running
sudo systemctl status k3s
sudo k3s kubectl get nodes

# Check ZFS (if you set up data pools)
sudo zpool status
```

## Disk Layout

After installation, your disk will have:

```
/dev/sda (512GB)
├─ /dev/sda1 (1GB)    - EFI System Partition (/boot)
└─ /dev/sda2 (511GB)  - BTRFS with subvolumes:
   ├─ @root           → /                  (compressed)
   ├─ @home           → /home              (compressed)
   ├─ @nix            → /nix               (nodatacow)
   ├─ @var-log        → /var/log           (compressed, 10GB quota)
   ├─ @rancher        → /var/lib/rancher   (nodatacow, 250GB quota)
   └─ @snapshots      → /.snapshots        (for backups)
```

## Updating Disk Device

If you need to install on a different disk (e.g., NVMe instead of SATA):

Edit `hosts/jarvis/disko.nix` and change line 20:
```nix
device = "/dev/nvme0n1";  # Change from /dev/sda
```

Or override at install time:
```bash
--arg disks '{ main = "/dev/nvme0n1"; }'
```

## Troubleshooting

### Disko fails with "device busy"
```bash
# Unmount everything
sudo umount -R /mnt
# Retry disko
```

### Wrong disk selected
Double-check with `lsblk` before running disko!

### Need to start over
```bash
sudo umount -R /mnt
sudo wipefs -a /dev/sdX  # DANGER: Erases disk
# Re-run disko
```

## Next Steps

After successful installation:

1. **Set up user password**: `passwd liberis`
2. **Configure SSH keys**: `~/.ssh/authorized_keys`
3. **Set up ZFS data pools** (if using ZFS for media storage)
4. **Deploy k3s applications** (Jellyfin, *arr stack, etc.)
5. **Configure backups** using BTRFS snapshots

## Useful Commands

```bash
# Check BTRFS compression savings
sudo compsize /

# Manual snapshot before updates
sudo btrfs subvolume snapshot / /.snapshots/root-$(date +%Y%m%d-%H%M%S)

# Check disk usage per subvolume
sudo btrfs filesystem usage /

# View quota limits
sudo btrfs qgroup show /

# Adjust quota (if needed)
sudo btrfs qgroup limit 300G /@rancher /
```
