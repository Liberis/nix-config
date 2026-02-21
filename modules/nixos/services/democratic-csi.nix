{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.democratic-csi-user;

  # Wrappers that restrict file operations to /tank/k8s paths only
  mkRestrictedPath = cmd: bin: pkgs.writeShellScript "democratic-csi-${cmd}" ''
    TARGET="''${@: -1}"
    RESOLVED=$(realpath -m "$TARGET" 2>/dev/null || echo "$TARGET")
    if [[ "$RESOLVED" != /tank/k8s/* ]]; then
      echo "Error: ${cmd} only allowed under /tank/k8s/, got: $RESOLVED" >&2
      exit 1
    fi
    exec ${bin} "$@"
  '';
  restrictedChown = mkRestrictedPath "chown" "${pkgs.coreutils}/bin/chown";
  restrictedChmod = mkRestrictedPath "chmod" "${pkgs.coreutils}/bin/chmod";
  restrictedMkdir = mkRestrictedPath "mkdir" "${pkgs.coreutils}/bin/mkdir";

  # Wrappers that restrict zfs/zpool to tank/k8s datasets only
  restrictedZfs = pkgs.writeShellScript "democratic-csi-zfs" ''
    for arg in "$@"; do
      # Skip flags (start with -)
      [[ "$arg" == -* ]] && continue
      # Skip known subcommands
      case "$arg" in
        create|destroy|snapshot|clone|list|get|set|send|receive|rollback|rename|mount|unmount) continue ;;
      esac
      # Any dataset argument must be under tank/k8s
      if [[ "$arg" == */* ]] && [[ "$arg" != tank/k8s* ]]; then
        echo "Error: zfs only allowed on tank/k8s/* datasets, got: $arg" >&2
        exit 1
      fi
    done
    exec ${pkgs.zfs}/bin/zfs "$@"
  '';
  restrictedZpool = pkgs.writeShellScript "democratic-csi-zpool" ''
    # Only allow read-only zpool commands
    case "$1" in
      list|status|get)
        exec ${pkgs.zfs}/bin/zpool "$@"
        ;;
      *)
        echo "Error: only zpool list/status/get are allowed" >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.services.democratic-csi-user = {
    enable = mkEnableOption "Democratic CSI service user";

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "SSH public keys for democratic-csi authentication";
      example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... democratic-csi" ];
    };
  };

  config = mkIf cfg.enable {
    # Create dedicated group
    users.groups.democratic-csi = {
      gid = 994;
    };

    # Create system user
    users.users.democratic-csi = {
      isSystemUser = true;
      group = "democratic-csi";
      uid = 994;

      home = "/var/lib/democratic-csi";
      createHome = true;
      homeMode = "0750";

      # Needs shell for SSH command execution (democratic-csi runs ZFS commands over SSH)
      shell = pkgs.bash;

      hashedPassword = "!";

      openssh.authorizedKeys.keys = cfg.authorizedKeys;

      description = "Democratic CSI storage automation";
    };

    # Passwordless sudo for commands democratic-csi needs
    # ZFS operations use ZFS delegation (no sudo needed)
    # chown/chmod need sudo for setting volume permissions
    security.sudo.extraRules = [
      {
        users = [ "democratic-csi" ];
        commands = [
          { command = "${restrictedZfs} *"; options = [ "NOPASSWD" ]; }
          { command = "${restrictedZpool} *"; options = [ "NOPASSWD" ]; }
          { command = "${restrictedChown} *"; options = [ "NOPASSWD" ]; }
          { command = "${restrictedChmod} *"; options = [ "NOPASSWD" ]; }
          { command = "${restrictedMkdir} *"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];

    # Install restricted wrappers to known paths
    environment.etc."democratic-csi/zfs".source = restrictedZfs;
    environment.etc."democratic-csi/zpool".source = restrictedZpool;
    environment.etc."democratic-csi/chown".source = restrictedChown;
    environment.etc."democratic-csi/chmod".source = restrictedChmod;
    environment.etc."democratic-csi/mkdir".source = restrictedMkdir;

    # Restrict SSH for democratic-csi user
    services.openssh.extraConfig = ''
      Match User democratic-csi
        PermitTTY no
        X11Forwarding no
        AllowAgentForwarding no
        AllowTcpForwarding no
        PermitTunnel no
        PasswordAuthentication no
        PubkeyAuthentication yes
    '';

    # Set restrictive permissions on home directory
    systemd.tmpfiles.rules = [
      "d /var/lib/democratic-csi 0750 democratic-csi democratic-csi -"
      "d /var/lib/democratic-csi/.ssh 0700 democratic-csi democratic-csi -"
    ];

    # Assertions to ensure configuration is valid
    assertions = [
      {
        assertion = cfg.authorizedKeys != [];
        message = "democratic-csi user requires at least one SSH authorized key";
      }
    ];
  };
}
