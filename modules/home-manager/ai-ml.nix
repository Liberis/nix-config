{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # AI/LLM tools
    lmstudio # Local LLM inference UI
  ];
}
