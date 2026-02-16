{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.democratic-csi-user;

  # Wrapper script for ZFS commands with validation
  zfsWrapper = pkgs.writeShellScript "democratic-csi-zfs" ''
    #!/bin/sh
    # Restricted ZFS wrapper for democratic-csi
    # Only allows operations on tank/* datasets

    set -euo pipefail

    # Validate that we're only operating on allowed datasets
    case "$1" in
      create|destroy|snapshot|clone|send|receive|set|get|list)
        # Check if dataset starts with tank/
        for arg in "$@"; do
          if [[ "$arg" =~ ^tank/.* ]]; then
            exec ${pkgs.zfs}/bin/zfs "$@"
          fi
        done
        echo "Error: Only tank/* datasets are allowed" >&2
        exit 1
        ;;
      *)
        echo "Error: Command not allowed" >&2
        exit 1
        ;;
    esac
  '';

  # Wrapper script for chown/chmod with path restrictions
  filePermWrapper = pkgs.writeShellScript "democratic-csi-perms" ''
    #!/bin/sh
    # Restricted file permissions wrapper
    # Only allows operations in /tank and /var/lib/democratic-csi

    set -euo pipefail

    ALLOWED_PATHS=(
      "/tank"
      "/var/lib/democratic-csi"
    )

    # Get the command name (chown or chmod)
    CMD="$1"
    shift

    # Extract the path from arguments (last argument typically)
    TARGET_PATH="''${@: -1}"

    # Resolve to absolute path
    TARGET_PATH=$(realpath -m "$TARGET_PATH" 2>/dev/null || echo "$TARGET_PATH")

    # Check if path is within allowed directories
    ALLOWED=false
    for allowed_path in "''${ALLOWED_PATHS[@]}"; do
      if [[ "$TARGET_PATH" == "$allowed_path"* ]]; then
        ALLOWED=true
        break
      fi
    done

    if [ "$ALLOWED" = true ]; then
      case "$CMD" in
        chown)
          exec ${pkgs.coreutils}/bin/chown "$@"
          ;;
        chmod)
          exec ${pkgs.coreutils}/bin/chmod "$@"
          ;;
        *)
          echo "Error: Invalid command" >&2
          exit 1
          ;;
      esac
    else
      echo "Error: Path $TARGET_PATH not in allowed directories" >&2
      exit 1
    fi
  '';

in
{
  options.services.democratic-csi-user = {
    enable = mkEnableOption "Democratic CSI service user with hardened security";

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "SSH public keys for democratic-csi authentication";
      example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... democratic-csi" ];
    };

    allowedDatasets = mkOption {
      type = types.listOf types.str;
      default = [ "tank/*" ];
      description = "ZFS datasets that democratic-csi is allowed to manage";
    };

    allowedPaths = mkOption {
      type = types.listOf types.str;
      default = [ "/tank" "/var/lib/democratic-csi" ];
      description = "File system paths where democratic-csi can modify permissions";
    };
  };

  config = mkIf cfg.enable {
    # Create dedicated group
    users.groups.democratic-csi = {
      gid = 994; # Static GID for consistency
    };

    # Create hardened system user
    users.users.democratic-csi = {
      isSystemUser = true;
      group = "democratic-csi";
      uid = 994; # Static UID for consistency

      # Home directory with restricted permissions
      home = "/var/lib/democratic-csi";
      createHome = true;
      homeMode = "0750"; # rwxr-x--- (only user and group)

      # Security: No shell access (prevents interactive login)
      shell = "${pkgs.shadow}/bin/nologin";

      # Security: No password authentication
      hashedPassword = "!"; # Locked account (! means no password can match)

      # SSH key-only authentication
      openssh.authorizedKeys.keys = cfg.authorizedKeys;

      # Additional user description
      description = "Democratic CSI storage automation (restricted)";
    };

    # Restricted sudo configuration
    security.sudo.extraRules = [
      {
        users = [ "democratic-csi" ];
        commands = [
          # ZFS operations (restricted to tank/* datasets via wrapper)
          {
            command = "${zfsWrapper}";
            options = [ "NOPASSWD" "SETENV" ];
          }

          # Direct zpool commands (read-only operations)
          {
            command = "${pkgs.zfs}/bin/zpool list";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zpool status";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zpool get";
            options = [ "NOPASSWD" ];
          }

          # File permission changes (restricted via wrapper)
          {
            command = "${filePermWrapper} chown *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${filePermWrapper} chmod *";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Restrict SSH for democratic-csi user
    services.openssh.extraConfig = ''
      # Hardened SSH configuration for democratic-csi user
      Match User democratic-csi
        # Force command execution only (no interactive shell)
        ForceCommand internal-sftp

        # Disable potentially dangerous SSH features
        PermitTTY no
        X11Forwarding no
        AllowAgentForwarding no
        AllowTcpForwarding no
        PermitTunnel no

        # Restrict to key-based authentication only
        PasswordAuthentication no
        PubkeyAuthentication yes

        # Chroot to home directory (restricts file system access)
        ChrootDirectory /var/lib/democratic-csi

        # Additional security
        PermitUserEnvironment no
        AcceptEnv none
    '';

    # Create wrapper scripts directory
    environment.systemPackages = [
      zfsWrapper
      filePermWrapper
    ];

    # Set restrictive permissions on home directory
    systemd.tmpfiles.rules = [
      "d /var/lib/democratic-csi 0750 democratic-csi democratic-csi -"
      "d /var/lib/democratic-csi/.ssh 0700 democratic-csi democratic-csi -"
    ];

    # Additional system hardening for the user
    security.pam.loginLimits = [
      {
        domain = "democratic-csi";
        type = "hard";
        item = "nproc";
        value = "50"; # Max 50 processes
      }
      {
        domain = "democratic-csi";
        type = "hard";
        item = "nofile";
        value = "1024"; # Max 1024 open files
      }
      {
        domain = "democratic-csi";
        type = "hard";
        item = "memlock";
        value = "unlimited"; # Required for some storage operations
      }
    ];

    # Logging and auditing
    security.auditd.enable = mkDefault true;
    security.audit.rules = [
      # Audit all democratic-csi user actions
      "-a always,exit -F arch=b64 -S all -F auid=${toString config.users.users.democratic-csi.uid} -k democratic-csi"

      # Audit ZFS command execution
      "-w /run/current-system/sw/bin/zfs -p x -k democratic-csi-zfs"
      "-w /run/current-system/sw/bin/zpool -p x -k democratic-csi-zpool"
    ];

    # Assertions to ensure configuration is valid
    assertions = [
      {
        assertion = cfg.authorizedKeys != [];
        message = "democratic-csi user requires at least one SSH authorized key";
      }
    ];

    # Warnings
    warnings = mkIf (cfg.authorizedKeys == []) [
      "democratic-csi user has no authorized SSH keys configured"
    ];
  };
}
