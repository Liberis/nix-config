{ config, pkgs, ... }:
{
  # Configure fonts.  We explicitly declare the fonts packages we want
  # available on the system and override the default font set.  The
  # NerdFont override provides patched glyphs for development.
  fonts.fontconfig = {
    enable = true;
    includeUserConf = true;
    defaultFonts = {
      monospace = [ "Terminess Nerd Font" ];
      sansSerif = [ "Terminess Nerd Font" ];
      serif = [ "Terminess Nerd Font" ];
    };
    antialias = true;
    hinting.enable = true;
    hinting.style = "full"; # "slight" = smooth, "full" = crisp
    subpixel = {
      rgba = "rgb"; # disable subpixel AA; "rgb" = heavier
      lcdfilter = "light"; # skip LCD filtering, sharper edges
    };
  };

  fonts.packages = with pkgs; [
    terminus_font
    font-awesome
    corefonts
    dejavu_fonts
    fira-code
    noto-fonts
    vista-fonts
    nerd-fonts.mononoki
    nerd-fonts.anonymice
    nerd-fonts.jetbrains-mono
    nerd-fonts.terminess-ttf
    nerd-fonts.inconsolata
    nerd-fonts.iosevka
  ];
}
