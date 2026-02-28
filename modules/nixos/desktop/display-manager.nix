{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = import ../../../config.nix;

  # Wrapper script: configure outputs in cage before launching regreet
  # Cage (wlroots) auto-detects all outputs — we need to disable the TV
  # and set the correct mode on the 1440p monitor.
  # Connector names (DP-1, DP-2) may vary — check with wlr-randr if greeter
  # still shows on wrong output, and swap DP-1/DP-2 below.
  regreetWrapper = pkgs.writeShellScript "regreet-wrapper" ''
    wlr=${pkgs.wlr-randr}/bin/wlr-randr
    $wlr --output HDMI-A-1 --off
    $wlr --output DP-1 --mode 1920x1080@60Hz --pos 0,0
    $wlr --output DP-2 --mode 2560x1440@165Hz --pos 1920,0
    exec ${config.programs.regreet.package}/bin/regreet
  '';
in
{
  # greetd + regreet Display Manager Configuration
  # Uses cage (wlroots kiosk) with NVIDIA env vars and HDMI output disabled

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

  # NVIDIA env vars for cage (wlroots compositor used by greeter)
  systemd.services.greetd.environment = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Override cage command to use wrapper that disables HDMI before showing greeter
  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.cage}/bin/cage -s -- ${regreetWrapper}";

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
