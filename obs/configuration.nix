{ config, pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio.override {
      cudaSupport = true;
    };

    enableVirtualCamera = true;

    plugins = [
      pkgs.obs-studio-plugins.wlrobs
      pkgs.obs-studio-plugins.distroav
      pkgs.obs-studio-plugins.obs-vkcapture
    ];
  };
}
