{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Messaging applications
    telegram-desktop # Telegram messaging app
  ];
}
