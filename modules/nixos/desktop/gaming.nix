{ config, pkgs, lib, ... }:
{
  # Gaming configuration for NVIDIA desktop
  # Steam, Lutris, Proton, and performance tools

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    # Extra compatibility tools and env vars for xwayland-satellite
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Enable Gamemode for performance optimization
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  # 32-bit support for Steam/Wine
  hardware.graphics.enable32Bit = true;

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Game launchers
    lutris

    # Proton/Wine
    protonup-qt # Proton-GE installer
    wine-staging
    winetricks

    # Performance monitoring
    mangohud # Gaming overlay (FPS, GPU stats)
    nvtopPackages.full # NVIDIA GPU monitor

    # Vulkan tools
    vulkan-tools
    vulkan-loader
  ];

  # Gaming-specific environment variables for XWayland and Steam
  environment.sessionVariables = {
    # Steam/Proton optimizations
    STEAM_FORCE_DESKTOPUI_SCALING = "1.25"; # Match your AW2724DM scaling
    # Enable MangoHud for all Vulkan games
    MANGOHUD = "1";
    # NVIDIA-specific optimizations
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };
}
