{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Use latest NixOS kernel package (no custom compilation)
  # This provides a well-tested, pre-compiled kernel with all necessary drivers
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Kernel parameters for optimal performance and hardware support
  boot.kernelParams = [
    # AMD CPU optimizations - enable AMD P-State driver for better power management
    "amd_pstate=active"

    # NVIDIA Wayland support
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"

    # Boot and logging
    "quiet"
    "loglevel=3"

    # Performance tuning
    "nowatchdog" # Disable watchdog timers (slight performance gain)
    "transparent_hugepage=madvise" # Enable THP only when requested by applications
  ];

  # Enable all redistributable firmware
  # This includes firmware for AMD CPU/GPU, WiFi, Bluetooth, Ethernet, and other hardware
  hardware.enableRedistributableFirmware = true;

  # Kernel modules to load
  boot.kernelModules = [
    "kvm-amd"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Blacklist unneeded modules
  boot.blacklistedKernelModules = [
    "intel_rapl_common"
    "intel_rapl_msr"
  ];

  # System optimizations
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
