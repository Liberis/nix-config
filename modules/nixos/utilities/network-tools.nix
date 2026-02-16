{ config, pkgs, lib, ... }:

{
  # Network administration and diagnostic tools
  # These are specialized utilities for network management,
  # separate from basic networking configuration.

  # RouterOS management tool (Mikrotik devices)
  programs.winbox.enable = true;
  programs.winbox.openFirewall = true; # UDP 5678

  # Future: Add other network admin tools here
  # environment.systemPackages = with pkgs; [
  #   nmap         # Network scanner
  #   wireshark    # Packet analyzer
  #   traceroute   # Network path tracing
  #   tcpdump      # Packet capture
  #   mtr          # Network diagnostic tool
  # ];
}
