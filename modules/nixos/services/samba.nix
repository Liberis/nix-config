{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Samba/CIFS server configuration for network file sharing
  # Provides SMB shares for Windows/macOS/Linux clients

  services.samba = {
    enable = true;
    openFirewall = true;

    # Samba configuration
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "Jarvis Home Server";
        "netbios name" = "jarvis";
        security = "user";
        # Use stronger encryption
        "server min protocol" = "SMB2";
        "client min protocol" = "SMB2";
        # Performance tuning
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "read raw" = "yes";
        "write raw" = "yes";
        "max xmit" = 65535;
        "dead time" = 15;
        "getwd cache" = "yes";
      };

      # Media storage (read-only for most users)
      media = {
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        comment = "Media Library (Jellyfin)";
      };

      # Cloud storage (read-write)
      cloud = {
        path = "/mnt/cloud";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        comment = "Cloud Storage / NAS";
      };

      # Downloads (read-write)
      downloads = {
        path = "/mnt/downloads";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        comment = "Downloads (*arr stack)";
      };

      # Immich photos (read-write)
      immich = {
        path = "/mnt/immich";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        comment = "Photo Library (Immich)";
      };

      # Paperless documents (read-write)
      paperless = {
        path = "/mnt/paperless";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        comment = "Document Management (Paperless-ngx)";
      };

      # Backups (read-write)
      backups = {
        path = "/mnt/backups";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        comment = "Backup Storage";
      };
    };
  };

  # Samba client tools and utilities
  environment.systemPackages = with pkgs; [
    samba
    cifs-utils
  ];

  # Enable mDNS for easy discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
  };
}
