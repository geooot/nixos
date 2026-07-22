{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.flaresolverr.enable {
    services.flaresolverr = {
      enable = true;
      port = 8191;
    };
  };
}
