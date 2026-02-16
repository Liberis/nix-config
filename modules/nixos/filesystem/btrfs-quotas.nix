{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.btrfs-quotas;
in
{
  options.services.btrfs-quotas = {
    enable = mkEnableOption "BTRFS subvolume quotas";

    rootDevice = mkOption {
      type = types.str;
      default = "/";
      description = "The root filesystem path where BTRFS is mounted";
    };

    quotas = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        Quota limits for BTRFS subvolumes.
        Keys are subvolume paths (e.g., "@root", "@home")
        Values are size limits (e.g., "50G", "100G")
      '';
      example = {
        "@root" = "50G";
        "@home" = "100G";
        "@nix" = "200G";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure btrfs-progs is available
    environment.systemPackages = [ pkgs.btrfs-progs ];

    # Systemd service to configure BTRFS quotas at boot
    systemd.services.btrfs-setup-quotas = {
      description = "Configure BTRFS subvolume quotas";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -euo pipefail

        # Enable quotas on the root filesystem
        echo "Enabling BTRFS quotas on ${cfg.rootDevice}..."
        ${pkgs.btrfs-progs}/bin/btrfs quota enable ${cfg.rootDevice} 2>/dev/null || {
          # Quota might already be enabled
          if ${pkgs.btrfs-progs}/bin/btrfs qgroup show ${cfg.rootDevice} &>/dev/null; then
            echo "BTRFS quotas already enabled"
          else
            echo "Failed to enable BTRFS quotas"
            exit 1
          fi
        }

        # Wait a moment for quota to be fully enabled
        sleep 2

        # Apply quota limits to each subvolume
        ${concatStringsSep "\n" (mapAttrsToList (subvol: limit: ''
          echo "Setting quota for ${subvol}: ${limit}"
          ${pkgs.btrfs-progs}/bin/btrfs qgroup limit ${limit} ${subvol} ${cfg.rootDevice} || {
            echo "Warning: Failed to set quota for ${subvol}"
          }
        '') cfg.quotas)}

        echo "BTRFS quotas configured successfully"

        # Show current quota status
        echo "Current quota status:"
        ${pkgs.btrfs-progs}/bin/btrfs qgroup show -reF ${cfg.rootDevice} || true
      '';
    };

    # Optional: Add a timer to periodically check quota usage
    systemd.timers.btrfs-quota-check = {
      description = "Check BTRFS quota usage weekly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    systemd.services.btrfs-quota-check = {
      description = "Check BTRFS quota usage and log warnings";
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        echo "=== BTRFS Quota Usage Report ==="
        ${pkgs.btrfs-progs}/bin/btrfs qgroup show -reF ${cfg.rootDevice} || echo "Failed to show quotas"

        # Check for subvolumes exceeding 90% of quota
        ${pkgs.btrfs-progs}/bin/btrfs qgroup show -reF --raw ${cfg.rootDevice} | \
          ${pkgs.gawk}/bin/awk 'NR>2 && $3 > 0 && ($2/$3) > 0.9 {
            printf "WARNING: Subvolume using %.0f%% of quota\n", ($2/$3)*100
          }'
      '';
    };
  };
}
