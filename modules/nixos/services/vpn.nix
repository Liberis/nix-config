{
  config,
  pkgs,
  lib,
  ...
}:
{
    services.mullvad-vpn.enable = true;
    services.resolved.enable = true;
  # Mullvad often works best with systemd-resolved enabled
}
