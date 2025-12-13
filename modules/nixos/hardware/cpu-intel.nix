{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Intel CPU-specific configuration
  # For Intel processors (Xeon, Core, etc.)

  # Intel KVM virtualization support
  boot.kernelModules = [ "kvm-intel" ];

  # Intel-specific kernel parameters
  boot.kernelParams = [
    # Intel P-State driver for better CPU power management and performance
    "intel_pstate=active"
  ];

  # Enable Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
