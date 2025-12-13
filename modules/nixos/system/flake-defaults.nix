# Flake-managed defaults
# This module sets common configuration that should be consistent across all hosts
# when using flakes. These settings are automatically applied by flake.nix.

{ config, lib, ... }:
let
  cfg = import ../../../config.nix;
in
{
  # Enable flakes and the new nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages (NVIDIA drivers, VS Code, etc.)
  nixpkgs.config.allowUnfree = cfg.system.allowUnfree;

  # NixOS state version - controls backwards compatibility
  # This is set centrally in config.nix
  system.stateVersion = cfg.system.stateVersion;
}
