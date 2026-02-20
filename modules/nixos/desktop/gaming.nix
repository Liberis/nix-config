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
}
