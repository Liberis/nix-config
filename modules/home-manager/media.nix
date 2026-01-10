{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Media control utilities
    playerctl # Media player control (play/pause/next/prev)

    # Screen brightness control
    brightnessctl # Screen brightness control
  ];
}
