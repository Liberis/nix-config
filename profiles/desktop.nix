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
  #   - NVIDIA GPU drivers (open kernel modules)
  #   - Wayland compositor support (Niri, Sway, River)
  #   - Audio via PipeWire
  #   - Bluetooth support
  #   - Display manager (SDDM with sugar-dark theme)
  #   - Desktop applications (Firefox, Chromium)
  #
  # Requirements:
  #   - Physical hardware with GPU
  #   - Bootloader support
  #
  # Used by: Desktop workstations, development machines
  #
  # Note: Service-specific configuration (K3s, NFS, etc.) should be
  # imported directly in host configuration files.

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

    # Hardware utilities
    ../modules/nixos/hardware/hardware-tools.nix
  ];
}
