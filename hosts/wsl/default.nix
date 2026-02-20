{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # WSL Development Environment
  # Minimal NixOS configuration for Windows Subsystem for Linux

  imports = [
    # ===================
    # Base System Modules
    # ===================
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/users.nix
    ../../modules/nixos/system/system-packages.nix
    ../../modules/nixos/system/base.nix

    # ===================
    # Services
    # ===================
    ../../modules/nixos/services/ssh.nix
  ] ++ lib.optionals (inputs ? nixos-wsl) [
    inputs.nixos-wsl.nixosModules.default
  ];

  # WSL-specific configuration
  wsl = lib.mkIf (inputs ? nixos-wsl) {
    enable = true;
    defaultUser = "liberis";
    startMenuLaunchers = true;
  };

  # Minimal filesystem (WSL manages this)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  # Disable bootloader (WSL doesn't use it)
  boot.loader.grub.enable = false;
  boot.isContainer = true;

  networking.dhcpcd.enable = false;
}
