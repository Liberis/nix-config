{ config, pkgs, lib, ... }:
{
  # Enable NetworkManager as the primary networking daemon.
  # Firewall is enabled by default; individual modules can open
  # specific ports as needed.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  programs.winbox = {
    enable = true;
    openFirewall = true; # Required for neighbor discovery (UDP 5678)
  };
  # DNS configuration - Pi-hole as primary, Cloudflare as fallback
  networking.nameservers = [
    "192.168.10.254"  # Pi-hole on jarvis
    "1.1.1.1"        # Cloudflare fallback
  ];

  # Prevent NetworkManager from overwriting DNS settings
  networking.networkmanager.dns = "none";

  # Local domain search
  networking.search = [ "jarvis.local" ];
}
