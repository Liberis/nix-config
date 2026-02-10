{ config, pkgs, lib, ... }:
{
  # smartctl_exporter - Prometheus exporter for S.M.A.R.T. disk metrics
  # Exposes disk health, temperature, power-on hours, and error counts
  services.prometheus.exporters.smartctl = {
    enable = true;
    port = 9633;
    extraFlags = [ "--smartctl.interval=60s" ];
  };

  # Allow Prometheus (in k8s) to scrape metrics
  networking.firewall.allowedTCPPorts = [ 9633 ];
}
