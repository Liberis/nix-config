{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ZFS filesystem support for storage pools
  # Optimized for 32GB RAM system with media server workloads
  # Provides ZFS kernel modules, tools, automatic scrubbing, and snapshots

  # Enable ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "tank" ]; # Auto-import tank pool at boot

  # ZFS kernel module - using stable LTS kernel for ZFS compatibility
  # ZFS is only officially supported on LTS kernels
  boot.kernelPackages = pkgs.linuxPackages;

  # ARC (cache) tuning for 32GB RAM
  # Following rule: 2GB base + 1GB/TB storage = 2 + 3 = 5GB minimum
  # Allocate 8GB max to ARC, leaving 24GB for k3s and services
  boot.kernelParams = [
    "zfs.zfs_arc_max=8589934592" # 8GB max
    "zfs.zfs_arc_min=5368709120" # 5GB min (recommended for 3TB pool)
  ];

  # Additional ZFS module parameters
  boot.extraModprobeConfig = ''
    # ARC tuning for media server workload
    options zfs zfs_arc_max=8589934592
    options zfs zfs_arc_min=5368709120
    # Prefetch tuning (good for sequential media reads)
    options zfs zfs_prefetch_disable=0
  '';

  # ZFS services
  services.zfs = {
    # Auto-scrub for data integrity (Sunday at 2 AM)
    autoScrub = {
      enable = true;
      interval = "Sun 02:00";
      pools = [ "tank" ]; # Only scrub the data pool
    };

    # Auto-snapshots for data protection
    autoSnapshot = {
      enable = true;
      frequent = 0; # Disable 15-min snapshots (not needed for media)
      hourly = 24; # Keep 24 hourly snapshots (1 day)
      daily = 14; # Keep 14 daily snapshots (2 weeks)
      weekly = 8; # Keep 8 weekly snapshots (2 months)
      monthly = 12; # Keep 12 monthly snapshots (1 year)
    };

    # TRIM support for SSDs
    trim = {
      enable = true;
      interval = "weekly";
    };

    # ZFS Event Daemon for monitoring
    zed.settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      ZED_EMAIL_VERBOSE = false;
      ZED_NOTIFY_VERBOSE = false;
    };
  };

  # ZFS tools and utilities
  environment.systemPackages = with pkgs; [
    zfs
    zfs-prune-snapshots
    sanoid # Advanced snapshot management
    mbuffer # Faster zfs send/receive
  ];

  #
  # Networking configuration for ZFS
  # Set a unique hostId for ZFS (required)
  # Generate your own with: head -c 8 /dev/urandom | od -A n -t x1 | tr -d ' \n'
  # Note: This should be overridden in the host configuration
  networking.hostId = lib.mkDefault "cd6f7b2cc48cf0e7";
}
