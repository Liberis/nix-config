{
  config,
  pkgs,
  lib,
  ...
}:
{
  # NFS server configuration for network file sharing
  # Provides NFSv4 server for Linux/macOS clients
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS
  services.nfs.server = {
    enable = true;
    nproc = 32;
    # Enable NFSv4 only (more secure, better performance)
  #   exports = ''
  #     # ZFS Shares - General purpose shared storage
  #     # all_squash: map all users to anonymous user
  #     # anonuid/anongid: specify the UID/GID for the anonymous user (1000 is typically the first user)
  #     /tank/shares   192.168.88.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)
  #   '';
 };
  #
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
