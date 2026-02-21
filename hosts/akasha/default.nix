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

  imports = [
    # ===================
    # Disk Configuration
    # ===================
    ./disko.nix

    # ===================
    # Base System Modules
    # ===================
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/fonts.nix
    ../../modules/nixos/system/users.nix
    ../../modules/nixos/system/networking.nix
    ../../modules/nixos/system/system-packages.nix
    ../../modules/nixos/system/base.nix
    ../../modules/nixos/filesystem/btrfs-quotas.nix

    # ===================
    # Hardware Modules
    # ===================
    ../../modules/nixos/hardware/cpu-intel.nix
    ../../modules/nixos/hardware/gpu-amd.nix
    ../../modules/nixos/hardware/zfs.nix

    # ===================
    # Services
    # ===================
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/k3s-agent.nix
    ../../modules/nixos/services/nfs.nix
    ../../modules/nixos/services/democratic-csi.nix
  ];

  # Boot loader (GRUB for existing installation)
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
    };
    efi.canTouchEfiVariables = true;
  };

  # K3s agent configuration (worker node with storage)
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.10.10:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };

  # Democratic CSI user (hardened for K3s ZFS storage automation)
  services.democratic-csi-user = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAZyRyuXGBHgFOG8zv72GKxs5ZexZeW/T+3IXjclAOo democratic-csi"
    ];
  };

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

  # Server-specific kernel parameters
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "nowatchdog"
    "transparent_hugepage=madvise"
  ];

  hardware.enableRedistributableFirmware = true;

  # Kernel sysctl tuning for server performance
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # Override hostId from zfs.nix
  networking.hostId = "8c3f9a2e";

  boot.supportedFilesystems = [ "btrfs" ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    MaxRetentionSec=7day
    MaxFileSec=1day
  '';

  # BTRFS quotas - ~500GB on 512GB SSD
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "80G";
      "@home" = "50G";
      "@nix" = "200G";
      "@var-log" = "20G";
      "@rancher" = "100G";
      "@snapshots" = "50G";
    };
  };
}
