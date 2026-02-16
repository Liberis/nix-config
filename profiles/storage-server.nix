{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Storage Server profile - ZFS storage and NFS sharing
  #
  # Provides:
  #   - ZFS filesystem with auto-scrub and snapshots
  #   - NFS server for network file sharing
  #
  # Requirements:
  #   - Hardware with sufficient storage (multiple drives recommended)
  #   - ZFS-compatible kernel (LTS)
  #
  # Used by: Storage servers providing shared storage to the cluster

  imports = [
    # ZFS storage pool management
    ../modules/nixos/hardware/zfs.nix

    # NFS server for sharing ZFS datasets
    ../modules/nixos/services/nfs.nix
  ];
}
