{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # ===================
    # Media Control
    # ===================
    playerctl # Media player control (play/pause/next/prev)
    brightnessctl # Screen brightness control

    # ===================
    # Video Players
    # ===================
    mpv # Lightweight video player
    vlc # VLC media player

    # ===================
    # Audio/Video Tools
    # ===================
    ffmpeg-full # Audio/video codec and conversion
    yt-dlp # YouTube/video downloader
    mediainfo # Media file information

    # ===================
    # Image Tools
    # ===================
    imagemagick # Image manipulation CLI
    gimp # Image editor
    inkscape # Vector graphics editor

  ];

  # MPV configuration
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
      vo = "gpu";
      profile = "gpu-hq";
    };
  };
}
