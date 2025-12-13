{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Lenovo P510 ThinkStation - Home Server Configuration
  # Hardware: 28 cores, 32GB RAM, 512GB SSD, 4x 1TB HDDs
  #
  # Services:
  #   - K3s (Kubernetes cluster)
  #   - ZFS (storage pool)
  #   - SSH (remote access)

  imports = [
    # Declarative disk management (partitioning and filesystems)
    ./disko.nix
#    ./hardware-configuration.nix
    # Hardware-specific modules
    ../../modules/nixos/hardware/cpu-intel.nix # Intel Xeon E2680v5
    ../../modules/nixos/hardware/gpu-amd.nix # AMD R750 4GB

    # Storage and filesystems
    ../../modules/nixos/hardware/zfs.nix

    # Container orchestration - K3s Server
    ../../modules/nixos/services/k3s-base.nix

    # NFS server for sharing ZFS datasets
    ../../modules/nixos/services/nfs.nix
  ];

  # K3s server configuration
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tlsSans = [
      "192.168.10.11"
      "jarvis.local"
    ];
  };

  # Filesystem configuration is handled by disko.nix
  # See disko.nix for BTRFS subvolume layout:
  #   @root           -> /                (compressed, snapshots)
  #   @home           -> /home            (compressed, snapshots)
  #   @nix            -> /nix             (no CoW, no compression)
  #   @var-log        -> /var/log         (compressed)
  #   @rancher        -> /var/lib/rancher (no CoW for k3s performance)
  #   @snapshots      -> /.snapshots      (for backups)

  # Hardware modules (Lenovo P510 ThinkStation)
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
  ];
  # Kernel configuration
  # Note: CPU-specific settings (kvm-intel, intel_pstate) are in cpu-intel.nix
  # Note: Generic kernel settings are in the kernel module (if imported via profile)
  # Note: Kernel version is set by zfs.nix to ensure ZFS compatibility (uses LTS kernel)

  # Server-specific kernel parameters
  boot.kernelParams = [
    # Boot and logging
    "quiet"
    "loglevel=3"

    # Performance tuning for server workloads
    "nowatchdog" # Disable watchdog timers
    "transparent_hugepage=madvise" # Enable THP only when requested
  ];

  # Enable redistributable firmware
  hardware.enableRedistributableFirmware = true;

  # Kernel sysctl tuning for server performance
  boot.kernel.sysctl = {
    # Network performance (important for K3s/containers)
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";

    # Virtual memory tuning
    "vm.swappiness" = 10; # Prefer RAM over swap
    "vm.vfs_cache_pressure" = 50; # Keep inodes/dentries cached
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # File handles for container workloads
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # Unique host ID for ZFS (required when ZFS is enabled)
  # Generated with: head -c 8 /dev/urandom | od -A n -t x1 | tr -d ' \n'
  networking.hostId = "8c3f9a2e";

  # BTRFS filesystem support
  boot.supportedFilesystems = [ "btrfs" ];

  # BTRFS tools
  environment.systemPackages = with pkgs; [
    btrfs-progs # BTRFS utilities (btrfs, mkfs.btrfs, etc.)
    compsize # Check compression ratio
  ];

  # Systemd journal limits to prevent log overflow
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    MaxRetentionSec=7day
    MaxFileSec=1day
  '';

  # Systemd service to set BTRFS quotas on boot
  # TODO: Enable after system is stable
  # systemd.services.btrfs-setup-quotas = {
  #   description = "Set BTRFS subvolume quotas";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "local-fs.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     # Enable quotas if not already enabled
  #     ${pkgs.btrfs-progs}/bin/btrfs quota enable / 2>/dev/null || true
  #
  #     # Set quotas for subvolumes (only if not already set)
  #     ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 50G /@root / 2>/dev/null || true
  #     ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 20G /@home / 2>/dev/null || true
  #     ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 150G /@nix / 2>/dev/null || true
  #     ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 10G /@var-log / 2>/dev/null || true
  #     ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 250G /@rancher / 2>/dev/null || true
  #
  #     echo "BTRFS quotas configured"
  #   '';
  # };
}
