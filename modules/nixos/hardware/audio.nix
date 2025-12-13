{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Audio configuration using PipeWire
  # Provides: PulseAudio, ALSA, and JACK support via PipeWire
  # Used in: desktop role

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = false;
  };

  security.rtkit.enable = true;

  # Install additional audio control applications at the system level.  These
  # programs provide simple GUIs or CLI mixers for managing sound devices.
  environment.systemPackages = with pkgs; [ pulsemixer ];
}
