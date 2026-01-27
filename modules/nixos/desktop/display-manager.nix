{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = import ../../../config.nix;
  sddm-sugar-dark = pkgs.callPackage ./sddm-sugar-dark.nix { };
in
{
  # SDDM Display Manager Configuration
  # Modern Qt-based display manager

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "sugar-dark";
    };

    # Ensure niri session is available
    sessionPackages = [ pkgs.niri ];
  };

  # Install SDDM theme
  environment.systemPackages = [ sddm-sugar-dark ];

  # Create cache directory
  systemd.tmpfiles.rules = [
    "d ${cfg.desktop.cacheDir} 0700 ${cfg.user.name} ${cfg.user.name} -"
  ];
}
