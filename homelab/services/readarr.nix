{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.readarr.enable {
    services.readarr = {
      enable = true;
      group = cfg.mediaGroup;
      dataDir = "/var/lib/readarr";
    };
  };
}
