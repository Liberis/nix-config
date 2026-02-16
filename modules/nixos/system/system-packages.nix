{ config, pkgs, ... }:
{
  # Base system utilities installed on every system.
  # User-specific CLI tools (ripgrep, fd, jq, fzf, etc.) are installed
  # via Home Manager in home/liberis/cli.nix instead.
  environment.systemPackages = with pkgs; [
    # Version control
    git

    # Network utilities
    inetutils # telnet, ftp, etc.
    iperf # Network bandwidth testing
    curl # HTTP client
    wget # Download utility
    bind # DNS utilities (dig, nslookup)

    # Hardware information
    pciutils # lspci
    usbutils # lsusb
    lshw # Hardware lister
    dmidecode # BIOS/system info

    # System monitoring
    iftop # Network traffic monitor
    iotop # I/O monitoring
    smartmontools # Disk health (smartctl)
    lm_sensors # Temperature monitoring

    # Disk utilities
    hdparm # Disk performance tuning
    gparted # Partition editor (GUI)
    parted # Partition tools (CLI)

    # Security
    openssl # SSL/TLS utilities, certificate management

    # File utilities
    vim # Text editor
    unzip # Archive extraction
    tree # Directory visualization
    bashmount # Bash mount wrapper

    # Process utilities
    psmisc # killall, fuser, pstree, etc.
  ];
}
