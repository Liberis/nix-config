{ config, pkgs, lib, ... }:
{
  # Desktop Workstation - Gaming & Development Machine (Dual-boot with Windows 11)
  # Hardware: AMD Ryzen 9 9900X, NVIDIA RTX 5070Ti, 64GB DDR5
  # Storage:
  #   - 1TB NVMe (/dev/nvme0n1):
  #     - Partition 1 (100MB): EFI (shared with Windows)
  #     - Partition 3 (300GB): Windows C:
  #     - Partition 4 (400GB): Games (NTFS, shared with Windows)
  #     - Partition 5 (16GB): NixOS Swap
  #     - Partition 6 (284GB): NixOS Root (BTRFS with subvolumes)
  #   - 2TB NVMe PCIe5 (/dev/nvme1n1):
  #     - Partition 1 (2TB): K3s Storage (BTRFS)
  #
  # Role: Desktop workstation and Kubernetes GPU worker
  #   - Dual-boot with Windows 11 (Windows installed first)
  #   - Full Wayland desktop environment
  #   - K3s agent with NVIDIA GPU support
  #   - NFS client for accessing shared storage from akasha
  #   - Dedicated 2TB K3s storage for persistent volumes
  #   - Shared 400GB NTFS partition for games (accessible from both OSes)
  imports = [
    # Hardware configuration for dual-boot setup
    # NOTE: For dual-boot with Windows, we use hardware-configuration.nix
    # instead of disko.nix (manual partitioning required)
    # ./disko.nix  # Only use for fresh single-OS install
    ./hardware-configuration.nix  # Generated during NixOS installation

    # Hardware-specific modules
    ../../modules/nixos/hardware/cpu-amd.nix # AMD Ryzen 9 9900X
    ../../modules/nixos/hardware/gpu-nvidia.nix # NVIDIA RTX 5070Ti

    # K3s with NVIDIA GPU support for container workloads
    ../../modules/nixos/services/k3s-nvidia.nix

    # Container orchestration - K3s Server
    ../../modules/nixos/services/k3s-base.nix
    ../../modules/nixos/services/vpn.nix
    # NFS server for sharing ZFS datasets
    ../../modules/nixos/services/nfs.nix
  ];

  # Secrets management
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    secrets = {
      "k3s/agent-token-jarvis" = {
        mode = "0400";
        owner = "root";
        group = "root";
        path = "/var/lib/rancher/k3s/agent-token";
      };
    };
  };

  # K3s agent configuration - connect to mainframe control plane
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.10.11:6443"; # Connect to mainframe control plane
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };

  # Dual-boot configuration with Windows 11
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # Shared EFI partition with Windows
    };
    timeout = 5; # Show boot menu for 5 seconds to choose OS
  };

  # Use local time for hardware clock (Windows compatibility)
  # Windows uses local time by default, while Linux uses UTC
  # This prevents time desync when switching between OSes
  time.hardwareClockInLocalTime = true;

  # Filesystem support for BTRFS and NTFS
  boot.supportedFilesystems = [ "btrfs" "ntfs" ];

  # Mount 400GB Games partition (NTFS, shared with Windows)
  # Appears as D: in Windows, /mnt/games in NixOS
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-label/Games"; # Or /dev/nvme0n1p4
    fsType = "ntfs";
    options = [
      "rw" # Read-write access
      "uid=1000" # Your user ID (adjust if different)
      "gid=100" # Users group
      "dmask=022" # Directory permissions (755)
      "fmask=133" # File permissions (644)
    ];
  };

  # Mount 2TB K3s storage drive (BTRFS)
  # Used for K3s persistent volumes, Longhorn storage, etc.
  fileSystems."/mnt/k3s-storage" = {
    device = "/dev/disk/by-label/k3s-storage"; # Or /dev/nvme1n1p1
    fsType = "btrfs";
    options = [
      "noatime" # Don't update access times
      "compress=zstd" # Enable compression
    ];
  };

  # System packages for NTFS and dual-boot management
  environment.systemPackages = with pkgs; [
    ntfs3g # NTFS filesystem driver
    efibootmgr # Manage UEFI boot entries
  ];

  # Hardware modules for AMD Ryzen 9900X
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  boot.kernelModules = [ "kvm-amd" ];

  # Enable redistributable firmware (includes AMD microcode)
  hardware.enableRedistributableFirmware = true;

  # BTRFS quotas to prevent any subvolume from filling the disk
  # Total available: ~284GB BTRFS partition (dual-boot setup)
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "60G";       # OS files - desktop needs more for GUI apps
      "@home" = "100G";      # User files - documents, downloads, configs
      "@nix" = "80G";        # Nix store - desktop packages (GUI, games, dev tools)
      "@var-log" = "10G";    # Logs - desktop usage is lighter
      "@rancher" = "20G";    # K3s worker data - GPU workloads use K3s storage
      "@snapshots" = "14G";  # BTRFS snapshots for backups
    };
    # Total allocated: 284G
    # Note: Games stored on separate 400GB NTFS partition (/mnt/games)
    # Note: K3s volumes stored on separate 2TB drive (/mnt/k3s-storage)
  };
}
