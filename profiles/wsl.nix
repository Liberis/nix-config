{
  config,
  pkgs,
  lib,
  inputs ? { },
  ...
}:
{
  # WSL profile - Windows Subsystem for Linux configuration
  #
  # Provides:
  #   - SSH server for remote access
  #   - WSL-specific optimizations
  #   - nixos-wsl integration (when available)
  #
  # Requirements:
  #   - WSL2 environment
  #   - nixos-wsl flake input (automatically imported if available)
  #
  # Used by: WSL instances on Windows machines

  imports = [
    # Remote access
    ../modules/nixos/services/ssh.nix
  ]
  ++ lib.optionals (inputs ? nixos-wsl) [
    # nixos-wsl integration (if available)
    inputs.nixos-wsl.nixosModules.default
  ];

  # WSL-specific configuration (only if nixos-wsl is available)
  config = lib.mkIf (inputs ? nixos-wsl) {
    wsl = {
      enable = true;
      defaultUser = "liberis";
      startMenuLaunchers = true;
    };
  };
}
