{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Dell OptiPlex 3080 - K3s Control Plane
  # Hardware: Intel i7-10710T (6 cores), 16GB RAM, 256GB NVMe
  #
  # Role: Dedicated Kubernetes control plane
  #   - K3s server (cluster init)
  #   - No storage workloads
  #   - Minimal headless configuration
  #
  # This server acts as the central control plane for the entire K3s cluster.
  # All worker nodes (jarvis, akasha) connect to this server.

  imports = [
    # Declarative disk management (partitioning and filesystems)
    ./disko.nix

    # Hardware-specific modules
    ../../modules/nixos/hardware/cpu-intel.nix # Intel i7-10710T

    # K3s control plane
    ../../modules/nixos/services/k3s-base.nix
  ];

  # K3s server configuration (control plane)
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;

    # Allow connections from worker nodes
    tlsSans = [
      "192.168.10.10" # Static IP for mainframe
      "mainframe.local"
      "mainframe"
    ];
  };

  # Hardware modules (Dell OptiPlex 3080)
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  # Kernel modules
  boot.kernelModules = [ "kvm-intel" ];

  # Enable redistributable firmware
  hardware.enableRedistributableFirmware = true;

  # Network configuration
  # Set a static IP for the control plane (recommended for stability)
  # Adjust to match your network configuration
  networking.interfaces.eno1.ipv4.addresses = [
    {
      address = "192.168.10.10";
      prefixLength = 24;
    }
  ];

  # Unique host ID (generated randomly)
  # Generate with: head -c 8 /dev/urandom | od -A n -t x1 | tr -d ' \n'
  networking.hostId = "a1b2c3d4";

  # Control plane specific optimizations
  boot.kernel.sysctl = {
    # Network performance (important for K3s API server)
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";

    # Connection tracking for K3s
    "net.netfilter.nf_conntrack_max" = 1000000;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;

    # File handles for K8s API server
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # Systemd journal limits
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    SystemMaxFileSize=100M
    MaxRetentionSec=30day
  '';

  # BTRFS quotas to prevent any subvolume from filling the disk
  # Total available: ~240GB on 256GB NVMe (512MB EFI + 8GB swap used)
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "50G";       # OS files - control plane needs less
      "@home" = "10G";       # Minimal home usage (headless)
      "@nix" = "80G";        # Nix store - moderate size for control plane
      "@var-log" = "10G";    # Logs - K8s API server logs
      "@rancher" = "80G";    # K3s etcd data - CRITICAL, needs room to grow
      "@snapshots" = "10G";  # BTRFS snapshots
    };
    # Total allocated: 240G (matches available space)
  };
}
