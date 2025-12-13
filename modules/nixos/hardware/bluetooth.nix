{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Hardware-level Bluetooth and WiFi configuration
  # Includes workarounds for ath12k WiFi/BT coexistence issues

  boot.extraModprobeConfig = ''
    # Disable WiFi/BT coexistence completely
    options ath12k coex_disable=1

    # Disable power saving
    options ath12k ps_disable=1

    # Disable Bluetooth autosuspend
    options btusb enable_autosuspend=0

    # Disable ERTM (can cause HID issues with coexistence)
    options bluetooth disable_ertm=1
  '';

  # Disable WiFi power saving
  networking.networkmanager.wifi.powersave = false;

  # USB power management off (helps with BT/WiFi stability)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  # Bluetooth settings optimized for HID devices
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        FastConnectable = true;
        IdleTimeout = 0;
      };
    };
  };

  # Blueman GUI for Bluetooth management
  services.blueman.enable = true;
}
