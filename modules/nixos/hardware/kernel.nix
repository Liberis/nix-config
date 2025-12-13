{
  config,
  pkgs,
  lib,
  ...
}:

{
  # System-agnostic kernel configuration
  # CPU and GPU-specific settings should be in separate modules:
  #   - cpu-intel.nix or cpu-amd.nix
  #   - gpu-nvidia.nix or gpu-amd.nix

  # Use latest NixOS kernel package (no custom compilation)
  # This provides a well-tested, pre-compiled kernel with all necessary drivers
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Generic kernel parameters (not CPU/GPU specific)
  boot.kernelParams = [
    # Boot and logging
    "quiet"
    "loglevel=3"

    # Performance tuning
    "nowatchdog" # Disable watchdog timers (slight performance gain)
    "transparent_hugepage=madvise" # Enable THP only when requested by applications
  ];

  # Enable all redistributable firmware
  # This includes firmware for CPU/GPU, WiFi, Bluetooth, Ethernet, and other hardware
  hardware.enableRedistributableFirmware = true;

  # System optimizations (generic, not hardware-specific)
  boot.kernel.sysctl = {
    # Network performance
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";

    # Virtual memory
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # File handles
    "fs.file-max" = 2097152;
  };
}
