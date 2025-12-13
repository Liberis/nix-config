{ config, pkgs, ... }:
let
  cfg = import ../../../config.nix;
in
{
  # Set your timezone and locale preferences.  These options control
  # the system clock, locale environment variables and default
  # character encodings.
  time.timeZone = cfg.system.timezone;
  i18n.defaultLocale = cfg.system.locale;
  i18n.extraLocaleSettings = {
    LC_ALL = cfg.system.locale;
    LANGUAGE = "en_US:en";
  };
}
