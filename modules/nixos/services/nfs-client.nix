{
  config,
  pkgs,
  lib,
  ...
}:
{
  # NFS client configuration for mounting network shares from jarvis
  # Server: jarvis (192.168.1.140)

  # Enable NFS client support
  boot.supportedFilesystems = [ "nfs" "nfs4" ];

  # NFS client tools
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  # Mount NFS shares from jarvis
  fileSystems."/mnt/shares" = {
    device = "192.168.1.140:/mnt/shares";
    fsType = "nfs4";
    options = [
      "nofail"        # Don't fail boot if server is unavailable
      "x-systemd.automount" # Auto-mount on access
      "x-systemd.idle-timeout=600" # Unmount after 10 minutes of inactivity
      "noatime"       # Don't update access times (performance)
      "rw"            # Read-write access
    ];
  };

  # Ensure network is up before mounting NFS shares
  systemd.mounts = lib.mkIf (config.fileSystems ? "/mnt/shares") [
    {
      where = "/mnt/shares";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
    }
  ];

  # Firewall: NFS client doesn't need incoming ports
  # but may need outgoing to 2049, 111, 20048 (usually allowed by default)
}
