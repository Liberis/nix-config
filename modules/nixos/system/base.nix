{ config, pkgs, ... }:
{
  # Base services enabled for all scenarios.  The display server and
  # other scenario‑specific services are configured in the scenario
  # files.
  services.dbus.enable = true;
  security.polkit.enable = true;
  services.printing.enable = false;
}
