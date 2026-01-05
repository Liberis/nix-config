{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = import ../../../config.nix;
in
{
  # Display manager configuration using greetd + regreet
  # Provides login menu for multiple Wayland compositors (River, Niri, Sway)

  # No compositor assertions - users can enable whichever compositors they want

  # Copy wallpaper asset for the login screen
  # Path: modules/nixos/desktop/ -> modules/nixos/ -> modules/ -> nix-flakes/assets/
  environment.etc."greetd/river_bg.png".source = ../../../assets/river_bg.png;

  # ReGreet configuration (GTK-based greeter)
  programs.regreet = {
    enable = true;
    settings = lib.mkForce {
      GTK = {
        theme_name = "Arc-Dark";
      };
      background = {
        path = "/etc/greetd/river_bg.png";
        fill = "Cover";
      };
      sessions = [
        {
          name = "River";
          command = "river -no-xwayland";
        }
        {
          name = "Niri";
          command = "niri-session";
        }
        {
          name = "Sway";
          command = "sway";
        }
      ];
    };
  };

  # Greetd login manager
  services.greetd = {
    enable = true;
    # Run ReGreet inside cage compositor, on a single monitor
    settings.default_session = {
      # -s allows VT switching; -m last = use one monitor
      command = "${pkgs.cage}/bin/cage -s -m last ${config.programs.regreet.package}/bin/regreet";
      user = cfg.desktop.defaultUser;
    };
  };

  # Create cache directory for regreet
  systemd.tmpfiles.rules = [
    "d ${cfg.desktop.cacheDir} 0700 ${cfg.user.name} ${cfg.user.name} -"
  ];
}
