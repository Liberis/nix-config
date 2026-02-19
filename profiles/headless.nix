{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Headless profile - Minimal headless server configuration
  #
  # Provides:
  #   - Bootloader configuration
  #   - SSH server for remote access
  #
  # Requirements:
  #   - None (minimal configuration)
  #
  # Used by: All headless servers (control plane, storage, etc.)

  imports = [
    # Boot

    # Remote access
    ../modules/nixos/services/ssh.nix
  ];
}
