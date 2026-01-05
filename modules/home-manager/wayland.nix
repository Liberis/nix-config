{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Core Wayland desktop components
    waybar # Status bar for Wayland compositors
    wofi # Application launcher
    foot # Terminal emulator
    wl-clipboard # Clipboard utilities
    wideriver # River layout generator
    way-displays # Display configuration tool
    wlr-randr # Output management tool
    bibata-cursors # Cursor theme
    conky # System monitor
    sway # Alternative Wayland compositor

    # Screenshot and screen recording
    grim # Screenshot utility
    slurp # Screen area selection
    wf-recorder # Screen recording

    # Notifications and widgets
    mako # Notification daemon
    swww # Wallpaper daemon
  ];

  # Link configuration directories for GUI applications
  xdg.configFile."way-displays" = {
    source = ../../config/way-displays;
    recursive = true;
  };
  xdg.configFile."waybar" = {
    source = ../../config/waybar;
    recursive = true;
  };
  xdg.configFile."wofi" = {
    source = ../../config/wofi;
    recursive = true;
  };
  xdg.configFile."foot" = {
    source = ../../config/foot;
    recursive = true;
  };
  xdg.configFile."river" = {
    source = ../../config/river;
    recursive = true;
  };
  xdg.configFile."niri" = {
    source = ../../config/niri;
    recursive = true;
  };
  xdg.configFile."sway" = {
    source = ../../config/sway;
    recursive = true;
  };
}
