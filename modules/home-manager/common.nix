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

  # Yazi file manager with plugins
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;

    plugins = {
      smart-enter = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "86d28e4fb4f25f36cc501b8cb0badb37a6b14263";
        hash = "sha256-hEnrvfJwCAgM12QwPmjHEwF5xNrwqZH1fTIb/QG0NFI=";
      } + "/smart-enter.yazi";
    };

    flavors = {
      dracula = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "ffe6e3a16c5c51d7e2dedacf8de662fe2413f73a";
        hash = "sha256-hEnrvfJwCAgM12QwPmjHEwF5xNrwqZH1fTIb/QG0NFI=";
      } + "/dracula.yazi";
    };
  };

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

  # Link individual yazi config files (not the whole directory)
  # This allows home-manager to manage plugins/flavors separately
  # xdg.configFile."yazi/yazi.toml".source = ../../config/yazi/yazi.toml;
  # xdg.configFile."yazi/keymap.toml".source = ../../config/yazi/keymap.toml;
  # xdg.configFile."yazi/theme.toml".source = ../../config/yazi/theme.toml;
  # xdg.configFile."yazi/init.lua".source = ../../config/yazi/init.lua;
  # xdg.configFile."yazi/plugin.toml".source = ../../config/yazi/plugin.toml;
  #
  # No packages installed here - use role-specific modules
  home.packages = with pkgs; [ ];
}
