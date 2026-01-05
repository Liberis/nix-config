{
  config,
  pkgs,
  lib,
  ...
}:
{
  # System-wide Wayland packages (themes and compositor tools)
  environment.systemPackages = with pkgs; [
    arc-theme # GTK theme
    cage # Wayland kiosk compositor (used by greetd)
  ];
}
