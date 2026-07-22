{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = lib.mkIf cfg.services.prowlarr.enable {
    services.prowlarr.enable = true;

    # The upstream module uses DynamicUser, which gives an unstable UID and
    # makes migrating config files fragile. Pin a real user in the media
    # group so /var/lib/prowlarr keeps stable ownership.
    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "prowlarr";
      Group = cfg.mediaGroup;
    };

    users.users.prowlarr = {
      isSystemUser = true;
      group = cfg.mediaGroup;
      home = "/var/lib/prowlarr";
    };
  };
}
