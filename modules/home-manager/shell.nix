{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Shell enhancements
    zsh # Z shell
    detox
    # Modern CLI replacements
    claude-code
    zoxide # Smarter cd for jumping to frequently used directories
    bat # A cat clone with syntax highlighting
    eza # A modern replacement for ls
    ripgrep # Fast recursive search respecting .gitignore
    fd # User-friendly find alternative
    jq # Command-line JSON processor
    fzf # Fuzzy finder for files, history and more
    tldr # Simplified man pages with community examples
    convmv
    # Terminal UI applications
    lazygit # Terminal UI for Git operations
    ncspot # Spotify terminal client
    fastfetch # System information display
    # Disk and file utilities
    ncdu # NCurses disk usage analyzer
    dust # Disk usage visualization in a tree view
    dua # Interactive disk usage analyser and cleanup tool
    zip
    unzip
    file # File type detection
  ];
}
