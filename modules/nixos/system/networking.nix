{ config, pkgs, lib, ... }:
{
  # Enable NetworkManager as the primary networking daemon.
  # Firewall is enabled by default; individual modules can open
  # specific ports as needed.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # DNS configuration - Pi-hole as primary, Cloudflare as fallback
  networking.nameservers = [
    "192.168.1.140"  # Pi-hole on jarvis
    "1.1.1.1"        # Cloudflare fallback
  ];

  # Prevent NetworkManager from overwriting DNS settings
  networking.networkmanager.dns = "none";

  # Local domain search
  networking.search = [ "jarvis.local" ];
}
