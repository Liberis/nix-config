{
  config,
  pkgs,
  lib,
  ...
}:
{
  # System-wide Wayland packages
  environment.systemPackages = with pkgs; [
    # Add any additional Wayland packages here if needed
  ];
}
