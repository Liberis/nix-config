{
  config,
  pkgs,
  lib,
  ...
}:
{
  # K3s with NVIDIA GPU container support
  # Extends k3s-base.nix with NVIDIA-specific configuration

  # Import base k3s configuration
  imports = [ ./k3s-base.nix ];

  hardware.nvidia-container-toolkit = {
    enable = true;

    extraArgs = [
      "--disable-hook"
      "create-symlinks"
    ];

  }; # --- Additional NVIDIA-specific packages ---
  environment.systemPackages = with pkgs; [
    libnvidia-container # Provides nvidia-container-cli
    #nvidia-container-toolkit

  ];

}
