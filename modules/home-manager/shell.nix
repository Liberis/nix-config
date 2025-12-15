{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Shell enhancements
    starship # Modern shell prompt
    zsh # Z shell
    detox
    # Modern CLI replacements
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
  ];
}
