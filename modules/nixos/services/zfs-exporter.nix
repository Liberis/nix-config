{ config, pkgs, lib, ... }:
{
  # zfs_exporter - Prometheus exporter for ZFS pool and dataset metrics
  # Exposes pool health, capacity, ARC cache stats, errors, fragmentation
  services.prometheus.exporters.zfs = {
    enable = true;
    port = 9134;
  };

  # Allow Prometheus (in k8s) to scrape metrics
  networking.firewall.allowedTCPPorts = [ 9134 ];
}
