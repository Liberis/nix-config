{ config, pkgs, ... }:
{
  # Desktop host-specific configuration
  # This file contains only hardware and configuration specific to this machine
  imports = [
    ./hardware-configuration.nix
    # K3s with NVIDIA GPU support for container workloads
    ../../modules/nixos/services/k3s-nvidia.nix
  ];
}
