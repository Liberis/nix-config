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
    device = "192.168.10.11:/mnt/shares";
    fsType = "nfs4";
    options = [
      "nofail"        # Don't fail boot if server is unavailable
      "x-systemd.automount" # Auto-mount on access
      "x-systemd.idle-timeout=600" # Unmount after 10 minutes of inactivity
      "noatime"       # Don't update access times (performance)
      "rw"            # Read-write access
      "user"          # Allow regular user to mount/unmount
    ];
  };

  # Create the mount point directory with user ownership
  # This allows the user to access the mount without sudo
  systemd.tmpfiles.rules = [
    "d /mnt/shares 0755 liberis users -"
  ];

  # Firewall: NFS client doesn't need incoming ports
  # but may need outgoing to 2049, 111, 20048 (usually allowed by default)
}
