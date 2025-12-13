#!/usr/bin/env bash
# ZFS Dataset Creation Script for Jarvis Home Server
# Run this after creating the tank pool during installation

set -e

echo "Creating ZFS datasets for Jarvis home server..."
echo "Pool: tank (4x 1TB RAIDZ1)"
echo ""

# Media storage for Jellyfin
# Large files, sequential access, light compression
echo "Creating tank/media (Jellyfin media storage)..."
zfs create \
  -o recordsize=1M \
  -o compression=lz4 \
  -o atime=off \
  -o mountpoint=/mnt/media \
  tank/media

# Subdirectories for organized media
zfs create tank/media/movies
zfs create tank/media/tv
zfs create tank/media/music
zfs create tank/media/books

# Downloads for *arr stack
# Mixed file sizes, moderate I/O
echo "Creating tank/downloads (*arr stack downloads)..."
zfs create \
  -o recordsize=128K \
  -o compression=lz4 \
  -o atime=off \
  -o mountpoint=/mnt/downloads \
  tank/downloads

# k3s persistent volumes
# Mixed workload, container data
echo "Creating tank/k3s (Kubernetes persistent volumes)..."
zfs create \
  -o recordsize=128K \
  -o compression=lz4 \
  -o atime=off \
  -o xattr=sa \
  -o mountpoint=/mnt/k3s \
  tank/k3s

# Paperless-ngx documents
# Document storage, good compression potential
echo "Creating tank/paperless (Paperless-ngx documents)..."
zfs create \
  -o recordsize=128K \
  -o compression=zstd \
  -o atime=off \
  -o mountpoint=/mnt/paperless \
  tank/paperless

# Subdirectories for paperless
zfs create tank/paperless/data
zfs create tank/paperless/media
zfs create tank/paperless/export

# Immich photos
# Large files, RAW photos, high-res images
echo "Creating tank/immich (Immich photo storage)..."
zfs create \
  -o recordsize=1M \
  -o compression=lz4 \
  -o atime=off \
  -o mountpoint=/mnt/immich \
  tank/immich

# Subdirectories for immich
zfs create tank/immich/upload
zfs create tank/immich/library
zfs create tank/immich/thumbs

# Cloud storage / general NAS
# Mixed files, user data
echo "Creating tank/cloud (Cloud/NAS storage)..."
zfs create \
  -o recordsize=128K \
  -o compression=lz4 \
  -o atime=off \
  -o mountpoint=/mnt/cloud \
  tank/cloud

# Firefly III database
# Database workload, small random I/O
echo "Creating tank/firefly (Firefly III database)..."
zfs create \
  -o recordsize=8K \
  -o compression=lz4 \
  -o logbias=throughput \
  -o primarycache=metadata \
  -o mountpoint=/mnt/firefly \
  tank/firefly

# Backups
# Large files, maximum compression
echo "Creating tank/backups (Backup storage)..."
zfs create \
  -o recordsize=1M \
  -o compression=zstd-3 \
  -o atime=off \
  -o mountpoint=/mnt/backups \
  tank/backups

echo ""
echo "Dataset creation complete!"
echo ""
echo "Created datasets:"
zfs list -r tank
echo ""
echo "Compression ratios:"
zfs get compressratio -r tank
echo ""
echo "Storage usage:"
zpool list tank
echo ""
echo "Next steps:"
echo "1. Set appropriate permissions on mount points"
echo "2. Deploy k3s applications"
echo "3. Configure applications to use these mount points"
