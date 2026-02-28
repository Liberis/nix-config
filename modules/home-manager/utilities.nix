{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Wayland clipboard manager
    cliphist # Clipboard manager with history (requires Wayland)
    # GUI torrent client
    deluge
    # LaTeX editor and compiler
    texstudio
    texlive.combined.scheme-medium
  ];
}
