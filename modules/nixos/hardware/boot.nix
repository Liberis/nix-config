{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
      useOSProber = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = false;
  };
}
