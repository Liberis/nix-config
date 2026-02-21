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
  # greetd Display Manager Configuration
  # Minimal, fast greeter with regreet (GTK4 GUI)
  # Perfect for Wayland compositors and multi-monitor setups

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.regreet}/bin/regreet";
        user = "greeter";
      };
    };
  };

  # Enable regreet (GTK4 greeter for greetd)
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
        cursor_theme_name = "Bibata-Modern-Ice";
        font_name = "Inter 11";
        icon_theme_name = "Papirus-Dark";
        theme_name = "Adwaita-dark";
      };
      appearance = {
        greeting_msg = "Welcome back!";
      };
    };
  };

  # Ensure niri and other Wayland sessions are available
  services.displayManager.sessionPackages = [ pkgs.niri ];

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
