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
      # ZFS Shares - General purpose shared storage
      /mnt/shares   192.168.1.0/24(rw,sync,no_subtree_check,root_squash)
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
