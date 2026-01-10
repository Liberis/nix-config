{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Disk usage analyzers
    ncdu # NCurses disk usage analyzer
    dust # Disk usage visualization in a tree view
    dua # Interactive disk usage analyser and cleanup tool
    zip
    unzip
    deluge
    # Clipboard manager
    cliphist # Clipboard manager with history
    # File type detection (required for yazi previews)
    file
  ];
}
