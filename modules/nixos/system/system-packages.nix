{ config, pkgs, ... }:
{
  # Base system utilities installed on every system.
  # User-specific CLI tools (ripgrep, fd, jq, fzf, etc.) are installed
  # via Home Manager in home/liberis/cli.nix instead.
  environment.systemPackages = with pkgs; [
    git
    inetutils
    pciutils
    usbutils
    lshw
    iftop
    iotop
    iperf
    openssl
    dmidecode
    smartmontools
    lm_sensors
    hdparm
    vim
    iperf
    curl
    wget
    bashmount
    unzip
    tree
    psmisc
    bind
    gparted
    parted
  ];
}
