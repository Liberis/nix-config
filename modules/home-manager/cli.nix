{ config, pkgs, ... }:
{
  # User‑level CLI packages for the liberis user.
  # Essential CLI tools that don't belong to specific feature categories.
  # Most tools have been moved to feature-specific modules:
  # - development.nix: Programming languages and cloud CLIs
  # - shell.nix: Shell enhancements and modern CLI tools
  # - utilities.nix: Disk analyzers and system tools
  home.packages = with pkgs; [
    # Claude Code assistant
    claude-code
    opencode
  ];
}
