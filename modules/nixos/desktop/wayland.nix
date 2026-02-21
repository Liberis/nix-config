{ config, pkgs, ... }:
{
  # Wayland compositor and portal configuration
  # Sets up XDG portals for desktop integration and session variables
  #
  # This module contains:
  #   - XDG portals (wlr, gtk)
  #   - System-level Wayland utilities (session management, locking, power)
  #   - Wayland environment variables
  #   - Seat management (seatd)
  #   - Sway compositor configuration
  #
  # User-level Wayland packages (waybar, wofi, foot, etc.) are in:
  #   - modules/home-manager/wayland.nix

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    # Modern XDG portal configuration format
    config.common.default = [
      "wlr"
      "gtk"
    ];
  };

  # System packages for Wayland session management
  environment.systemPackages = with pkgs; [
    swayidle
    waylock # Screen locker
    wlopm # Power management for monitors
    wlrctl # Window management for wlroots compositors
    playerctl # Media player control
    jq # JSON processor (used by sway scripts)
    xwayland # X11 compatibility layer for Wayland (required for Steam and other X11 apps)
  ];

  # Wayland-specific environment variables
  # Note: XDG_CURRENT_DESKTOP is set by the compositor session itself (river, niri-session, sway, etc.)
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron/Chromium apps
    FREETYPE_PROPERTIES = "truetype:interpreter-version=35";
    QT_SCALE_FACTOR = "1";
    QT_FONT_DPI = "96";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
  };

  # Enable seatd for seat management (required for Wayland compositors)
  services.seatd.enable = true;

  # Enable Sway with proper wrappers and permissions
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # PAM configuration for waylock
  security.pam.services.waylock = { };
}
