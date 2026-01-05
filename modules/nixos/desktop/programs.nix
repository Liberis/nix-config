{ config, pkgs, ... }:
{
  # Programs enabled on desktop systems
  # These programs are appropriate for graphical machines and are not
  # enabled on servers or WSL environments.

  # Web browser
  programs.firefox.enable = true;

  # River compositor (Wayland window manager)
  programs.river-classic.enable = true;

  # Niri compositor (scrolling tiling Wayland compositor)
  programs.niri.enable = true;
}
