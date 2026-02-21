{ config, pkgs, lib, ... }:
{
  # Desktop Workstation - Gaming & Development Machine
  # Hardware: AMD Ryzen 9 9900X, NVIDIA RTX 5070Ti, 64GB DDR5
  # Storage:
  #   - 1TB NVMe (/dev/nvme0n1): OS Drive
  #     - ESP (1GB): EFI boot
  #     - Swap (32GB): Encrypted swap
  #     - Root (~930GB): BTRFS with subvolumes
  #   - 2TB NVMe (/dev/nvme1n1): Data Drive
  #     - Data (2TB): BTRFS (@k3s-storage, @games, @media, @downloads)

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
    ../../modules/nixos/utilities/network-tools.nix

    # ===================
    # Hardware Modules
    # ===================
    ../../modules/nixos/hardware/cpu-amd.nix
    ../../modules/nixos/hardware/gpu-nvidia.nix
    ../../modules/nixos/hardware/kernel.nix
    ../../modules/nixos/hardware/audio.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/hardware-tools.nix

    # ===================
    # Desktop Environment
    # ===================
    ../../modules/nixos/desktop/wayland.nix
    ../../modules/nixos/desktop/display-manager.nix
    ../../modules/nixos/desktop/programs.nix
    ../../modules/nixos/desktop/gaming.nix

    # ===================
    # Services
    # ===================
    ../../modules/nixos/services/k3s-agent-nvidia.nix
  ];

  # K3s agent configuration - connect to mainframe control plane
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.10.11:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };

  # Boot loader
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
    };
    efi.canTouchEfiVariables = true;
  };

  # Filesystem support
  boot.supportedFilesystems = [ "btrfs" ];

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

  hardware.enableRedistributableFirmware = true;

  # System packages
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  # BTRFS quotas - ~930GB OS partition
  services.btrfs-quotas = {
    enable = true;
    rootDevice = "/";
    quotas = {
      "@root" = "100G";
      "@home" = "400G";
      "@nix" = "200G";
      "@var-log" = "20G";
      "@rancher" = "50G";
      "@snapshots" = "160G";
    };
  };
}
