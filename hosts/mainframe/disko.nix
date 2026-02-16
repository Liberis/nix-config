{
  # Disko configuration for OptiPlex 3080
  # Declarative disk partitioning and formatting for 256GB NVMe
  #
  # K3s control plane optimized layout:
  #   - Separate /var/lib/rancher for etcd data (nodatacow for performance)
  #   - Minimal subvolumes (no desktop bloat)
  #   - Compressed logs and root
  #
  # Usage during installation:
  #   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /path/to/this/flake#optiplex
  #
  # Or specify device:
  #   sudo nix run github:nix-community/disko -- --mode disko --arg disks '{ main = "/dev/nvme0n1"; }' /path/to/this/flake#optiplex

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Adjust to your NVMe device
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition
            ESP = {
              priority = 1;
              size = "512M";
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

            # Swap partition (8GB for 16GB RAM system)
            swap = {
              priority = 2;
              size = "8G";
              content = {
                type = "swap";
                randomEncryption = true; # Encrypt swap for security
              };
            };

            # BTRFS root partition with subvolumes
            root = {
              priority = 3;
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L nixos"
                ];
                subvolumes = {
                  # Root subvolume - OS files
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Home subvolume - minimal (server, no user files)
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

                  # Rancher subvolume - K3s control plane data (etcd)
                  # CRITICAL: nodatacow for etcd performance
                  "@rancher" = {
                    mountpoint = "/var/lib/rancher";
                    mountOptions = [
                      "noatime"
                      "nodatacow" # Essential for etcd performance
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
