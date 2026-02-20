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

    # ===================
    # Services
    # ===================
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/k3s-server.nix
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

  # K3s server configuration (control plane)
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tlsSans = [
      "192.168.10.10"
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

  boot.kernelModules = [ "kvm-intel" ];

  hardware.enableRedistributableFirmware = true;

  # Network configuration - static IP for control plane
  networking.interfaces.eno1.ipv4.addresses = [
    {
      address = "192.168.10.10";
      prefixLength = 24;
    }
  ];

  networking.hostId = "a1b2c3d4";

  # Control plane optimizations
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";
    "net.netfilter.nf_conntrack_max" = 1000000;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  services.journald.extraConfig = ''
    SystemMaxUse=2G
    SystemMaxFileSize=100M
    MaxRetentionSec=30day
  '';

  # BTRFS quotas - ~240GB on 256GB NVMe
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "50G";
      "@home" = "10G";
      "@nix" = "80G";
      "@var-log" = "10G";
      "@rancher" = "80G";
      "@snapshots" = "10G";
    };
  };
}
