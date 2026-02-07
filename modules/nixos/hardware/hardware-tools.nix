{
  config,
  pkgs,
  lib,
  ...
}:
{
  # System-wide utility packages for desktop systems
  environment.systemPackages = with pkgs; [
    openssl
    rasdaemon
    edac-utils
    powertop # Power management analysis tool
    solaar # Logitech device manager
    hdparm
    hd-idle
  ];

services.rasdaemon.enable = true;

}
