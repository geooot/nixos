{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.jellyfin.enable {
    # jellyfin-ffmpeg already has NVENC/CUVID compiled in, and
    # addDriverRunpath is in nativeBuildInputs — but upstream postFixup
    # only patches the .so files, not the ffmpeg binary. Without the
    # driver runpath on the binary, cuInit() can't find libcuda.so at
    # /run/opengl-driver/lib. This overlay extends postFixup to also
    # patch the binaries, eliminating the need for LD_LIBRARY_PATH.
    nixpkgs.overlays = [
      (final: prev: {
        jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            addDriverRunpath ${placeholder "bin"}/bin/ffmpeg
            addDriverRunpath ${placeholder "bin"}/bin/ffprobe
          '';
        });
      })
    ];

    services.jellyfin = {
      enable = true;
      group = cfg.mediaGroup;
      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/dri/renderD128";
      };
    };

    # The NixOS jellyfin module only allows /dev/dri/renderD128 in the
    # device cgroup, but CUDA also needs the NVIDIA character devices.
    # Without these, cuInit() fails with CUDA_ERROR_NO_DEVICE.
    systemd.services.jellyfin.serviceConfig.DeviceAllow = [
      "/dev/nvidia0 rw"
      "/dev/nvidiactl rw"
      "/dev/nvidia-uvm rw"
      "/dev/nvidia-uvm-tools rw"
    ];
  };
}
