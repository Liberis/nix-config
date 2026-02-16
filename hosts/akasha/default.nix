{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Lenovo P510 ThinkStation - Storage Server & K3s Worker
  # Hardware: Intel Xeon E2680v5 (28 cores), 64GB RAM, 512GB SSD, 4x 1TB HDDs
  #
  # Role: Storage server and Kubernetes worker node
  #   - K3s agent (worker node)
  #   - ZFS storage pool (tank - RAIDZ1)
  #   - NFS server for cluster storage
  #   - SSH remote access

  imports = [
    # Declarative disk management (partitioning and filesystems)
    ./disko.nix
#    ./hardware-configuration.nix
    # Hardware-specific modules
    ../../modules/nixos/hardware/cpu-intel.nix # Intel Xeon E2680v5
    ../../modules/nixos/hardware/gpu-amd.nix # AMD R750 4GB

    # Container orchestration - K3s Worker
    ../../modules/nixos/services/k3s-base.nix

    # Democratic CSI user (for K3s CSI driver with ZFS)
    ../../modules/nixos/services/democratic-csi.nix
  ];

  # K3s agent configuration (worker node with storage)
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.10.10:6443"; # Connect to mainframe control plane
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };

  # Democratic CSI user (hardened for K3s ZFS storage automation)
  services.democratic-csi-user = {
    enable = true;

    # SSH public key for authentication (key-only, no password)
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAZyRyuXGBHgFOG8zv72GKxs5ZexZeW/T+3IXjclAOo democratic-csi"
    ];

    # Restrict ZFS operations to tank/* datasets only
    allowedDatasets = [ "tank/*" ];

    # Restrict file permission changes to these paths only
    allowedPaths = [
      "/tank"
      "/var/lib/democratic-csi"
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

  # BTRFS quotas to prevent any subvolume from filling the disk
  # Total available: ~500GB on 512GB SSD
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "80G";       # OS files - plenty of room for system updates
      "@home" = "50G";       # Minimal home usage (headless server)
      "@nix" = "200G";       # Nix store - largest allocation for packages
      "@var-log" = "20G";    # Logs - with compression, this is generous
      "@rancher" = "100G";   # K3s data - etcd, images, local volumes
      "@snapshots" = "50G";  # BTRFS snapshots for backups
    };
    # Total allocated: 500G (leaves headroom for metadata and overhead)
  };
}
