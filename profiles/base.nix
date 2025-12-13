{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Base profile - Common configuration for ALL hosts
  # This profile is imported by every system regardless of role
  #
  # Provides:
  #   - Locale and timezone settings
  #   - Font configuration
  #   - User account setup
  #   - Network management
  #   - Essential system packages
  #   - Base system services (dbus, polkit)

  imports = [
    ../modules/nixos/system/locale.nix
    ../modules/nixos/system/fonts.nix
    ../modules/nixos/system/users.nix
    ../modules/nixos/system/networking.nix
    ../modules/nixos/system/system-packages.nix
    ../modules/nixos/system/base.nix
  ];
}
