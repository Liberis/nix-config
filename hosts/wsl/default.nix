{ config, pkgs, ... }:
{
  # WSL host-specific configuration
  # Minimal filesystem configuration (WSL manages this)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  # Disable bootloader (WSL doesn't use it)
  boot.loader.grub.enable = false;

  # WSL-specific settings
  boot.isContainer = true;
  networking.dhcpcd.enable = false;
}
