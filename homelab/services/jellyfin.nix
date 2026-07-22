{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      group = cfg.mediaGroup;
      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/dri/renderD128";
      };
    };
  };
}
