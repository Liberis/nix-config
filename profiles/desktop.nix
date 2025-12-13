{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Desktop profile - Full graphical workstation configuration
  #
  # Provides:
  #   - NVIDIA GPU drivers (beta, open kernel)
  #   - Wayland compositor support (River)
  #   - Audio via PipeWire
  #   - Bluetooth support
  #   - Display manager (greetd + regreet)
  #   - Desktop applications
  #
  # Requirements:
  #   - Physical hardware with GPU
  #   - Bootloader support
  #
  # Used by: Desktop workstations, development machines
  #
  # Note: K3s (Kubernetes) is NOT included by default.
  # To add K3s, import ../modules/nixos/services/k3s-nvidia.nix in your host config.

  imports = [
    # Boot and kernel
    ../modules/nixos/hardware/boot.nix
    ../modules/nixos/hardware/kernel.nix

    # Graphics and display
    ../modules/nixos/hardware/gpu-nvidia.nix
    ../modules/nixos/desktop/wayland.nix
    ../modules/nixos/desktop/display-manager.nix

    # Hardware support
    ../modules/nixos/hardware/audio.nix
    ../modules/nixos/hardware/bluetooth.nix

    # Software and applications
    ../modules/nixos/desktop/programs.nix
    ../modules/nixos/desktop/wayland-packages.nix
    ../modules/nixos/services/k3s-nvidia.nix
    # Hardware utilities
    ../modules/nixos/hardware/hardware-tools.nix
  ];
}
