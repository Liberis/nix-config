{ config, pkgs, ... }:
{
  # SSH server configuration for remote access.
  # Enabled on server and WSL systems.
  services.openssh.enable = true;
}
