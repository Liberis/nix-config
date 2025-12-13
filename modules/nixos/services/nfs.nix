{
  config,
  pkgs,
  lib,
  ...
}:
{
  # NFS server configuration for network file sharing
  # Provides NFSv4 server for Linux/macOS clients

  services.nfs.server = {
    enable = true;
    # Enable NFSv4 only (more secure, better performance)
    exports = ''
      # Media storage (read-only for most clients)
      /mnt/media    192.168.1.0/24(ro,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)

      # Cloud storage (read-write for authenticated users)
      /mnt/cloud    192.168.1.0/24(rw,sync,no_subtree_check,root_squash)

      # Downloads (read-write for *arr stack management)
      /mnt/downloads 192.168.1.0/24(rw,sync,no_subtree_check,root_squash)

      # Immich photos (read-write for photo uploads)
      /mnt/immich   192.168.1.0/24(rw,sync,no_subtree_check,root_squash)

      # Paperless (read-write for document scanning)
      /mnt/paperless 192.168.1.0/24(rw,sync,no_subtree_check,root_squash)

      # Backups (read-write for backup clients)
      /mnt/backups  192.168.1.0/24(rw,sync,no_subtree_check,root_squash)
    '';
  };

  # Open NFS ports in firewall
  networking.firewall = {
    allowedTCPPorts = [
      2049 # NFS
      111 # portmapper
      20048 # mountd
    ];
    allowedUDPPorts = [
      2049 # NFS
      111 # portmapper
      20048 # mountd
    ];
  };

  # NFS client tools
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];
}
