{
  # =============================================================================
  # Disko configuration for jarvis desktop - Fresh Install
  # =============================================================================
  # Hardware: AMD Ryzen 9 9900X, NVIDIA RTX 5070Ti, 64GB DDR5
  #
  # Disk Layout:
  #   - 1TB NVMe (nvme0n1): OS Drive
  #     - ESP: 1GB (EFI boot)
  #     - Swap: 32GB (suspend-to-disk with 64GB RAM)
  #     - Root: ~930GB (BTRFS with subvolumes)
  #
  #   - 2TB NVMe (nvme1n1): Data Drive
  #     - Data: 2TB (BTRFS for K3s storage, games, media)
  #
  # Installation:
  #   1. Boot NixOS installer
  #   2. Run: sudo nix --experimental-features "nix-command flakes" run \
  #           github:nix-community/disko -- --mode disko ./hosts/jarvis/disko.nix
  #   3. Run: sudo nixos-install --flake .#jarvis
  #
  # IMPORTANT: This will DESTROY all data on both target disks!
  # =============================================================================

  disko.devices = {
    disk = {
      # =======================================================================
      # OS Drive - 1TB NVMe
      # =======================================================================
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
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

            # Swap partition (32GB for 64GB RAM - allows hibernate)
            swap = {
              priority = 2;
              size = "32G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            # BTRFS root partition with subvolumes (~930GB)
            root = {
              priority = 3;
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L" "nixos"
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

                  # Home subvolume - user files, documents, configs
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Nix store subvolume
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };

                  # Logs subvolume
                  "@var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # K3s worker data
                  "@rancher" = {
                    mountpoint = "/var/lib/rancher";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };

                  # Snapshots for backups
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

      # =======================================================================
      # Data Drive - 2TB NVMe
      # =======================================================================
      data = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            # Single BTRFS partition for all data (~2TB)
            data = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L" "data"
                ];
                subvolumes = {
                  # K3s persistent volume storage (Longhorn, etc.)
                  "@k3s-storage" = {
                    mountpoint = "/mnt/k3s-storage";
                    mountOptions = [
                      "noatime"
                      "compress=zstd"
                    ];
                  };

                  # Games storage
                  "@games" = {
                    mountpoint = "/mnt/games";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };

                  # Media storage (optional - for videos, music, etc.)
                  "@media" = {
                    mountpoint = "/mnt/media";
                    mountOptions = [
                      "noatime"
                      "compress=zstd"
                    ];
                  };

                  # Downloads (large files, ISOs, etc.)
                  "@downloads" = {
                    mountpoint = "/mnt/downloads";
                    mountOptions = [
                      "noatime"
                      "compress=zstd"
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
