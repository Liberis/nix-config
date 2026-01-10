# Home-Manager Integration Module
# This module handles the integration of home-manager with NixOS and provides
# role-based module selection to avoid installing unnecessary packages.
#
# The module selection is based on the roles assigned to the host:
# - All hosts get: common.nix, cli.nix
# - Server/WSL add: development.nix, shell.nix
# - Desktop adds: wayland.nix, media.nix, utilities.nix, communication.nix

{
  config,
  lib,
  roles ? [ ],
  ...
}:
let
  cfg = import ../config.nix;

  # Core modules imported for all roles
  coreModules = [
    ./home-manager/common.nix
    ./home-manager/cli.nix
  ];

  # Development and shell tools for server/wsl roles
  baseModules = [
    ./home-manager/development.nix
    ./home-manager/shell.nix
  ];

  # Desktop-specific modules
  desktopModules = [
    ./home-manager/wayland.nix
    ./home-manager/media.nix
    ./home-manager/utilities.nix
    ./home-manager/communication.nix
  ];

  # Determine which modules to import based on roles
  roleImports =
    if lib.any (r: r == "desktop") roles then
      coreModules ++ baseModules ++ desktopModules
    else
      coreModules ++ baseModules;
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${cfg.user.name}.imports = roleImports;
}
