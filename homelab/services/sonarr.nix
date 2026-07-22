{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.sonarr.enable {
    services.sonarr = {
      enable = true;
      group = cfg.mediaGroup;
      dataDir = "/var/lib/sonarr";
    };

    # Sonarr's module only manages StateDirectory at its default nested
    # dataDir; since we flatten it to /var/lib/sonarr, create the dir here.
    systemd.tmpfiles.settings."10-homelab-sonarr"."/var/lib/sonarr".d = {
      user = "sonarr";
      group = cfg.mediaGroup;
      mode = "0770";
    };
  };
}
