{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Desktop-specific hardware management tools
  # Note: openssl and hdparm are in system-packages.nix (available on all hosts)
  environment.systemPackages = with pkgs; [
    openssl
    edac-utils
    powertop # Power management analysis tool
    solaar # Logitech device manager (for Logitech peripherals)
    hd-idle # Spin down idle hard drives (useful for desktop with multiple drives)
  ];


}
