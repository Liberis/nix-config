{
  config,
  pkgs,
  lib,
  ...
}:
{
  # AMD GPU configuration (Radeon)
  # For AMD graphics cards (R7, R9, RX, etc.)

  # Enable graphics support
  hardware.graphics.enable = true;

  # Use AMD open-source drivers (amdgpu/radeon)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # AMD GPU kernel modules
  boot.kernelModules = [
    "amdgpu" # Modern AMD GPU driver (GCN 3.0+, including R7 250)
  ];

  # Optional: OpenGL/Vulkan packages for AMD
  # Note: RADV (the Mesa-based Vulkan driver) is enabled by default
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd # ROCm OpenCL
  ];
}
