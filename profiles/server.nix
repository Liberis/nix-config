{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Server profile - Minimal headless server configuration
  #
  # Provides:
  #   - Bootloader configuration
  #   - SSH server for remote access
  #
  # Requirements:
  #   - None (minimal configuration)
  #
  # Used by: Headless servers, remote access only

  imports = [
    # Boot
    ../modules/nixos/hardware/boot.nix

    # Remote access
    ../modules/nixos/services/ssh.nix
  ];
}
