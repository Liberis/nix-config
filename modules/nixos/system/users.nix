{ config, pkgs, ... }:
let
  cfg = import ../../../config.nix;
in
{
  # Define the primary user on the system.  Adjust the groups as
  # necessary for your use case.  Additional groups can be added in
  # host‑specific configuration if required.
  users.groups.democratic-csi = {};
  users.users.${cfg.user.name} = {
    isNormalUser = true;
    description = cfg.user.fullName;
    extraGroups = cfg.user.groups;
    packages = with pkgs; [ ];
  };
  users.users.democratic-csi = {
    isSystemUser = true;
    group = "democratic-csi";
    home = "/var/lib/democratic-csi";
    createHome = true;
    shell = "/run/current-system/sw/bin/bash";
    openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAZyRyuXGBHgFOG8zv72GKxs5ZexZeW/T+3IXjclAOo democratic-csi"
      # Add your generated public key here
      # "ssh-ed25519 AAAA... democratic-csi"
    ];
  };
  security.sudo.extraRules = [
    {
      users = [ "democratic-csi" ];
      commands = [
        { command = "/run/current-system/sw/bin/zfs"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/zpool"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/chown"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/chmod"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

}
