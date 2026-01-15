{ config, pkgs, ... }:
{
  # Desktop host-specific configuration (AMD Ryzen 9900X + NVIDIA 5070Ti)
  # This file contains only hardware and configuration specific to this machine
  imports = [
    ./hardware-configuration.nix

    # Hardware-specific modules
    ../../modules/nixos/hardware/cpu-amd.nix # AMD Ryzen 9900X
    # GPU config (NVIDIA 5070Ti) is in profiles/desktop.nix

    # K3s with NVIDIA GPU support for container workloads
    ../../modules/nixos/services/k3s-nvidia.nix

    # NFS client for mounting shares from jarvis
    ../../modules/nixos/services/nfs-client.nix
  ];

  # K3s agent configuration - connect to jarvis server
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.88.240:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
  };
}
