{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
in
{
  config = {
    users.groups.${cfg.mediaGroup} = { };

    # Jellyfin needs device access for hardware transcoding. The service
    # module creates the user with the media group; add it to the device
    # groups so it can reach /dev/nvidia* and /dev/dri/*.
    users.users.jellyfin.extraGroups = lib.mkIf cfg.services.jellyfin.enable [
      "video"
      "render"
    ];
  };
}
