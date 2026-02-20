{ config, pkgs, lib, ... }:
{
  # K3s Agent with NVIDIA GPU Support
  # For worker nodes with NVIDIA GPUs

  imports = [ ./k3s-agent.nix ];

  config = lib.mkIf config.services.k3s.enable {
    # NVIDIA container toolkit for GPU workloads
    hardware.nvidia-container-toolkit = {
      enable = true;
      extraArgs = [
        "--disable-hook"
        "create-symlinks"
      ];
    };

    environment.systemPackages = with pkgs; [
      libnvidia-container
    ];
  };
}
