{ config, pkgs, ... }:
{
  # Base system utilities installed on every system.
  # User-specific CLI tools (ripgrep, fd, jq, fzf, etc.) are installed
  # via Home Manager in home/liberis/cli.nix instead.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    bashmount
    unzip
    tree
    pciutils
    psmisc
    bind
    gparted
  ];
}
