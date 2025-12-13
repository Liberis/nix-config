{ config, pkgs, ... }:
let
  cfg = import ../../../config.nix;
in
{
  # Define the primary user on the system.  Adjust the groups as
  # necessary for your use case.  Additional groups can be added in
  # host‑specific configuration if required.
  users.users.${cfg.user.name} = {
    isNormalUser = true;
    description = cfg.user.fullName;
    extraGroups = cfg.user.groups;
    packages = with pkgs; [ ];
  };
}
