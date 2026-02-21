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

  # Git configuration with Conventional Commits enforcement
  programs.git = {
    enable = true;
    settings = {
      user.name = cfg.user.fullName;
      user.email = cfg.user.email;
      init.defaultBranch = "main";
      commit.template = "~/.config/git/commit-template";
      core.hooksPath = "~/.config/git/hooks";
      pull.rebase = true;
    };
  };

  xdg.configFile."git/commit-template".source = ../../config/git/commit-template;
  xdg.configFile."git/hooks/commit-msg" = {
    source = ../../config/git/hooks/commit-msg;
    executable = true;
  };

  # SSH client configuration with agent auto-loading
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/id_ed25519";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
      };
    };
  };

  # Auto-start ssh-agent via systemd user service
  services.ssh-agent.enable = true;

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
        hash = "sha256-m/gJTDm0cVkIdcQ1ZJliPqBhNKoCW1FciLkuq7D1mxo=";
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
