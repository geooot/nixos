{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.radarr.enable {
    services.radarr = {
      enable = true;
      group = cfg.mediaGroup;
      dataDir = "/var/lib/radarr";
      settings.server.port = 7876;
    };
  };
}
