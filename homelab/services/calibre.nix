{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.calibre.enable {
    services.calibre-server = {
      enable = true;
      group = cfg.mediaGroup;
      libraries = [ "${cfg.mediaDir}/books" ];
      host = "127.0.0.1";
      port = 8090;
    };

    services.calibre-web = {
      enable = true;
      group = cfg.mediaGroup;
      listen.ip = "127.0.0.1";
      listen.port = 8083;
      dataDir = "/var/lib/calibre-web";
      options = {
        calibreLibrary = "${cfg.mediaDir}/books";
        enableBookConversion = true;
      };
    };
  };
}
