# Common Home-Manager Configuration
# Base configuration applied to all users regardless of role.
# Provides essential home-manager setup, bash configuration, and core tools.

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = import ../../config.nix;
in
{
  # Basic Home-Manager setup
  home.username = cfg.user.name;
  home.homeDirectory = "/home/${cfg.user.name}";
  home.stateVersion = cfg.system.stateVersion;
  programs.home-manager.enable = true;

  # Core TUI programs - enabled for all users
  programs.neovim.enable = true;
  programs.tmux.enable = true;
  programs.btop.enable = true;
  programs.yazi.enable = true;

  # Bash shell configuration
  home.file.".bashrc".source = ../../config/bash/.bashrc;
  # Link configuration files for core programs

  xdg.configFile."nvim" = {
    source = ../../config/nvim;
    recursive = true;
  };

  xdg.configFile."tmux" = {
    source = ../../config/tmux;
    recursive = true;
  };

  xdg.configFile."btop" = {
    source = ../../config/btop;
    recursive = true;
  };

  xdg.configFile."yazi" = {
    source = ../../config/yazi;
    recursive = true;
  };

  # No packages installed here - use role-specific modules
  home.packages = with pkgs; [ ];
}
