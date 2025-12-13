{ config, pkgs, ... }:
{
  # Enable NetworkManager as the primary networking daemon.
  # Firewall is enabled by default; individual modules can open
  # specific ports as needed.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
