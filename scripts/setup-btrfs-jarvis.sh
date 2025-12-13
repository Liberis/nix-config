#!/usr/bin/env bash
# BTRFS Setup Script for Jarvis Server
# This script creates BTRFS subvolumes for the root filesystem
#
# Usage: Run this during NixOS installation after formatting the disk
#        sudo bash setup-btrfs-jarvis.sh /dev/sdX2
#
# Partition layout expected:
#   /dev/sdX1 - 1GB   EFI (vfat) - label: boot
#   /dev/sdX2 - 511GB BTRFS      - label: nixos

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <device>"
    echo "Example: $0 /dev/sda2"
    exit 1
fi

DEVICE="$1"
MOUNT_POINT="/mnt"

# Check if device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: Device $DEVICE does not exist"
    exit 1
fi

echo "=== BTRFS Setup for Jarvis Server ==="
echo "Device: $DEVICE"
echo "Mount point: $MOUNT_POINT"
echo ""
echo "WARNING: This will FORMAT $DEVICE and destroy all data!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Creating BTRFS filesystem..."
mkfs.btrfs -f -L nixos "$DEVICE"

echo ""
echo "Step 2: Mounting BTRFS root..."
mount "$DEVICE" "$MOUNT_POINT"

echo ""
echo "Step 3: Creating subvolumes..."
btrfs subvolume create "$MOUNT_POINT/@root"
btrfs subvolume create "$MOUNT_POINT/@home"
btrfs subvolume create "$MOUNT_POINT/@nix"
btrfs subvolume create "$MOUNT_POINT/@var-log"
btrfs subvolume create "$MOUNT_POINT/@rancher"
btrfs subvolume create "$MOUNT_POINT/@snapshots"

echo ""
echo "Step 4: Unmounting root..."
umount "$MOUNT_POINT"

echo ""
echo "Step 5: Mounting subvolumes..."
# Mount root subvolume
mount -o subvol=@root,compress=zstd,noatime "$DEVICE" "$MOUNT_POINT"

# Create mount points
mkdir -p "$MOUNT_POINT"/{home,nix,var/log,var/lib/rancher,.snapshots}

# Mount other subvolumes
mount -o subvol=@home,compress=zstd,noatime "$DEVICE" "$MOUNT_POINT/home"
mount -o subvol=@nix,noatime,nodatacow "$DEVICE" "$MOUNT_POINT/nix"
mount -o subvol=@var-log,compress=zstd,noatime "$DEVICE" "$MOUNT_POINT/var/log"
mount -o subvol=@rancher,noatime,nodatacow "$DEVICE" "$MOUNT_POINT/var/lib/rancher"
mount -o subvol=@snapshots,compress=zstd,noatime "$DEVICE" "$MOUNT_POINT/.snapshots"

echo ""
echo "Step 6: Creating additional directories..."
mkdir -p "$MOUNT_POINT/var/lib"

echo ""
echo "Step 7: Mounting EFI partition..."
if [ -b "${DEVICE%2}1" ]; then
    mkdir -p "$MOUNT_POINT/boot"
    mount "${DEVICE%2}1" "$MOUNT_POINT/boot"
    echo "EFI partition mounted at $MOUNT_POINT/boot"
else
    echo "WARNING: EFI partition not found at ${DEVICE%2}1"
    echo "You'll need to mount /boot manually"
fi

echo ""
echo "=== BTRFS Setup Complete ==="
echo ""
echo "Subvolumes created:"
btrfs subvolume list "$MOUNT_POINT"
echo ""
echo "Mounted filesystems:"
mount | grep "$MOUNT_POINT"
echo ""
echo "Next steps:"
echo "1. Generate NixOS configuration: nixos-generate-config --root /mnt"
echo "2. Replace /mnt/etc/nixos/hardware-configuration.nix with your jarvis config"
echo "3. Install NixOS: nixos-install --flake /path/to/config#jarvis"
echo ""
echo "Note: Quotas will be automatically set on first boot by systemd service"
