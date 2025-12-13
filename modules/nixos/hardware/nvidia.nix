{
  config,
  pkgs,
  lib,
  ...
}:
{
  # NVIDIA GPU configuration for Wayland
  # Uses beta drivers with open kernel modules for better performance
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Environment variables for NVIDIA on Wayland
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Workaround for hardware cursor issues on NVIDIA + Wayland
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
