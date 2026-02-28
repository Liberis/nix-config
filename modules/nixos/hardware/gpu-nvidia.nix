{
  config,
  pkgs,
  lib,
  ...
}:
{
  # NVIDIA GPU configuration for Wayland
  # Uses open kernel modules (required for Blackwell/RTX 50xx)
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

  # Enable NVIDIA framebuffer device for Wayland (570+ drivers)
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  # Environment variables for NVIDIA on Wayland
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
