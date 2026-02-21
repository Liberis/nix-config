{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = import ../../../config.nix;
in
{
  # greetd + regreet Display Manager Configuration
  # programs.regreet automatically configures greetd to launch regreet
  # inside cage (a minimal Wayland kiosk compositor)

  programs.regreet = {
    enable = true;
    settings = {
      # Optional: Add background image
      # background = {
      #   path = "/etc/greetd/background.jpg";
      #   fit = "Cover";
      # };
      GTK = {
        application_prefer_dark_theme = true;
        cursor_theme_name = lib.mkForce "Bibata-Modern-Ice";
        font_name = lib.mkForce "Inter 11";
        icon_theme_name = lib.mkForce "Papirus-Dark";
        theme_name = lib.mkForce "Adwaita-dark";
      };
      appearance = {
        greeting_msg = "Welcome back!";
      };
    };
  };

  # Ensure Wayland sessions are available in the greeter
  services.displayManager.sessionPackages = [
    pkgs.niri
    pkgs.hyprland
  ];

  # Install cursor theme and icons for regreet
  environment.systemPackages = with pkgs; [
    bibata-cursors
    papirus-icon-theme
  ];

  # Create cache directory
  systemd.tmpfiles.rules = [
    "d ${cfg.desktop.cacheDir} 0700 ${cfg.user.name} ${cfg.user.name} -"
  ];
}
