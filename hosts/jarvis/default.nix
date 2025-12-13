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

    # Storage and filesystems
    ../../modules/nixos/hardware/zfs.nix

    # Container orchestration
    ../../modules/nixos/services/k3s-base.nix
  ];

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
  boot.kernelModules = [ "kvm-intel" ];

  # Unique host ID for ZFS (required)
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
  # Quotas are set once and persist, but this ensures they're applied
  systemd.services.btrfs-setup-quotas = {
    description = "Set BTRFS subvolume quotas";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Enable quotas if not already enabled
      ${pkgs.btrfs-progs}/bin/btrfs quota enable / 2>/dev/null || true

      # Set quotas for subvolumes (only if not already set)
      ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 50G /@root / 2>/dev/null || true
      ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 20G /@home / 2>/dev/null || true
      ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 150G /@nix / 2>/dev/null || true
      ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 10G /@var-log / 2>/dev/null || true
      ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 250G /@rancher / 2>/dev/null || true

      echo "BTRFS quotas configured"
    '';
  };
}
