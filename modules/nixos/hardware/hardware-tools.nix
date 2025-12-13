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
    powertop # Power management analysis tool
    solaar # Logitech device manager
    hdparm
    hd-idle
  ];
}
