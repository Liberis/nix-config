{
  # Disko configuration for Jarvis server
  # Declarative disk partitioning and formatting for 512GB SSD
  #
  # Usage during installation:
  #   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /path/to/this/flake#jarvis
  #
  # This will automatically:
  #   - Partition the disk (1GB EFI + rest BTRFS)
  #   - Format filesystems
  #   - Create BTRFS subvolumes
  #   - Mount everything

  disko.devices = {
    disk = {
      main = {
        # Device path - will be passed at runtime or detected
        # Override with: --arg disks '{ main = "/dev/nvme0n1"; }'
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition
            ESP = {
              priority = 1;
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };

            # BTRFS root partition with subvolumes
            root = {
              priority = 2;
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L nixos"
                ]; # Force and set label
                subvolumes = {
                  # Root subvolume - OS files
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Home subvolume - user files
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Nix store subvolume - packages
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "noatime"
                      "nodatacow" # Disable CoW for better performance
                    ];
                  };

                  # Logs subvolume - system logs
                  "@var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Rancher subvolume - k3s data
                  "@rancher" = {
                    mountpoint = "/var/lib/rancher";
                    mountOptions = [
                      "noatime"
                      "nodatacow" # Disable CoW for k3s performance
                    ];
                  };

                  # Snapshots subvolume - for backups
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
