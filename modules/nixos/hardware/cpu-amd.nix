{
  config,
  pkgs,
  lib,
  ...
}:
{
  # AMD CPU-specific configuration
  # For AMD processors (Ryzen, Threadripper, EPYC, etc.)

  # AMD KVM virtualization support
  boot.kernelModules = [ "kvm-amd" ];

  # AMD-specific kernel parameters
  boot.kernelParams = [
    # AMD P-State driver for better CPU power management and performance
    "amd_pstate=active"
  ];

  # Enable AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
